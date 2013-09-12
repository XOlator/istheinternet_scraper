class WebPage < ActiveRecord::Base

  # self.per_page = 50

  # Nicer fetching by url name
  extend FriendlyId
  friendly_id :path, :use => :scoped, :scope => :web_site_id

  # Nokogiri
  require 'nokogiri'

  # File storage for HTML page
  include Paperclip::Glue
  has_attached_file :html_page, 
    :path => "system/web_pages/:attachment/:id_partition/:filename",
    :styles =>  {:original => {:format => :html, :processors => [:save_html]}}
  has_attached_file :screenshot, 
    :path => "system/web_pages/:attachment/:id_partition/:style.:extension",
    :styles => {:thumbnail => "", :pixel => ["1x>", :png]},
    :convert_options => {:thumbnail => "-gravity north -thumbnail 300x300^ -extent 300x300"}


  # --- Associations ----------------------------------------------------------

  belongs_to :web_site
  has_one :color_palette

  serialize :headers, Hash


  # --- Validations -----------------------------------------------------------

  validates :url, :presence => true, :format => {:with => /\Ahttp/i}


  # --- Scopes ----------------------------------------------------------------

  scope :available, where(:available => true)


  # --- Methods ---------------------------------------------------------------


  def filename
    f = File.basename(Addressable::URI.parse(self.url).path)
    (f.blank? ? 'index' : f)
  end

  # --- HTML scrape methods ---
  def scraped?; !!self.available? && self.html_page.exists?; end
  def rescrape?; !!self.available? && !self.html_page.exists?; end

  def rescrape!
    begin
      status = Timeout::timeout(15) do # 15 seconds
        io = open(self.url, :read_timeout => 15, "User-Agent" => CRAWLER_USER_AGENT, :allow_redirections => :all)
        io.class_eval { attr_accessor :original_filename }
        io.original_filename = [File.basename(self.filename), "html"].join('.')
        self.html_page = io

        # raise "X" 
        raise "Invalid content-type" unless io.content_type.match(/text\/html/i)

        # Additional information
        self.headers = io.meta.to_hash
        self.base_uri = io.base_uri.to_s # redirect?
        self.last_modified_at = io.last_modified
        self.charset = io.charset
        self.page_status = io.status[0]
      end

    rescue OpenURI::HTTPError => err
      self.html_page = nil
      self.html_page_updated_at = Time.now
      self.available = false
      self.page_status = err.io.status[0]

    rescue Timeout::Error => err
      puts "Fetch Page Error (Timeout): #{err}"

    rescue => err
      puts "Fetch Page Error (Error): #{err}"

    # Do save the record
    ensure
      self.save
    end
  end

  def parse!
    # page = Nokogiri::HTML(Paperclip.io_adapters.for(self.html_page).read)
    page = Nokogiri::HTML(open(self.html_page.url, :read_timeout => 15, "User-Agent" => CRAWLER_USER_AGENT))
    self.title = page.css('title').to_s
    self.meta_tags = page.css('meta').map{|m| t = {}; m.attributes.each{|k,v| t[k] = v.to_s}; t }
    self.save

    follow = page.css('meta[name="robots"]')[0].attributes['content'].to_s rescue 'index,follow'
    page.css('a[href]').each{|h| PageQueue::add(h.attributes['href']) } unless follow.match(/nofollow/i)  
  end


protected



end