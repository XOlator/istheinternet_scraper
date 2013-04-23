class WebPage < ActiveRecord::Base

  self.per_page = 50

  # Nicer fetching by url name
  extend FriendlyId
  friendly_id :path, :use => :scoped, :scope => :web_site_id

  # File storage for HTML page
  include Paperclip::Glue
  has_attached_file :html_page, 
    :path => "#{APP_ROOT}/public/storage/web_pages/:attachment/:id_partition/:filename",
    :styles =>  {:original => {:format => :html, :processors => [:save_html]}}
    # :default_url => 'https://popblock-assets.s3.amazonaws.com/user/missing/:attachment_:style.:extension',
    # :storage => :s3, :s3_credentials => "#{APP_ROOT}/s3.yml", 


  # --- Associations ----------------------------------------------------------

  belongs_to :web_site


  # --- Validations -----------------------------------------------------------


  # --- Methods ---------------------------------------------------------------


  def filename
    f = File.basename(URI.parse(self.url).path)
    (f.blank? ? 'index' : f)
  end

  # --- HTML scrape methods ---
  def rescrape?; !!self.available? && !self.html_page.exists?; end

  def rescrape!
    begin
      status = Timeout::timeout(15) do # 15 seconds
        io = open(self.url, :read_timeout => 15, "User-Agent" => CRAWLER_USER_AGENT, :allow_redirections => :all)
        io.class_eval { attr_accessor :original_filename }
        io.original_filename = [File.basename(self.filename), "html"].join('.')
        self.html_page = io

        # Additional information
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


protected



end