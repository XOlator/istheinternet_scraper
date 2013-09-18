class WebPage < ActiveRecord::Base

  # self.per_page = 50

  STEPS = [:none, :screenshot, :process, :scrape, :parse, :complete]


  # Nicer fetching by url name
  extend FriendlyId
  friendly_id :path, use: :scoped, scope: :web_site_id

  # Nokogiri
  require 'nokogiri'

  # File storage for HTML page
  include Paperclip::Glue

  has_attached_file :html_page, 
    path: "storage/web_pages/:attachment/:id_partition/:style/:filename",
    styles:  {
      original: {format: :html, processors: [:save_html]}
    }

  has_attached_file :screenshot, 
    path: "storage/web_pages/:attachment/:id_partition/:style.:extension",
    styles: {
      thumbnail: "",
      pixel: ["1x1#", :png]
    },
    convert_options: {
      thumbnail: "-gravity north -thumbnail 300x300^ -extent 300x300 -background white -flatten +matte",
      pixel: "-background white -flatten +matte"
    }


  # --- Associations ----------------------------------------------------------

  belongs_to :web_site
  has_one :color_palette

  serialize :headers, Hash


  # --- Validations -----------------------------------------------------------

  validates :url, presence: true, format: {with: /\Ahttp/i}


  # --- Scopes ----------------------------------------------------------------

  STEPS.each_with_index do |v,i|
    scope "#{v}?".to_sym, where('step_index >= ?', i)
  end
    

  scope :available, where(available: true)


  # --- Methods ---------------------------------------------------------------

  # Mark next step. Do save to ensure is passable
  def step!(s)
    return false unless STEPS.include?(s)
    self.save && self.update_attribute(:step_index, STEPS.index(s))
  end

  # Check if has completed step
  def step?(s)
    return false unless STEPS.include?(s)
    self.step_index >= STEPS.index(s)
  end

  # Get the current step
  def step; STEPS[self.step_index]; end



  def filename
    uri = Addressable::URI.parse(self.url)
    f = File.basename(uri.path)
    (f.blank? ? 'index' : f)
  end



  # --- HTML scrape methods ---
  def scraped?; !!self.available? && !self.html_page_file_size.blank?; end
  def rescrape?; !!self.available? && self.html_page_file_size.blank?; end

  def rescrape!
    begin
      Timeout::timeout(15) do # 15 seconds
        io = open(self.url, read_timeout: 15, "User-Agent" => CRAWLER_USER_AGENT, allow_redirections: :all)
        io.class_eval { attr_accessor :original_filename }
        io.original_filename = [File.basename(self.filename), "html"].join('.')
        self.html_page = io

        raise "Invalid content-type" unless io.content_type.match(/text\/html/i)

        # Additional information
        self.headers = io.meta.to_hash
        self.base_uri = io.base_uri.to_s # redirect?
        self.last_modified_at = io.last_modified
        self.charset = io.charset
        self.page_status = io.status[0]
        self.available = true
      end

    rescue OpenURI::HTTPError => err
      _debug("Fetch Page Error (OpenURI): #{err}", 1, self)
      self.html_page = nil
      self.html_page_updated_at = Time.now
      self.page_status = err.io.status[0]
      self.available = false

    rescue Timeout::Error => err
      _debug("Fetch Page Error (Timeout): #{err}", 1, self)

    rescue => err
      _debug("Fetch Page Error (Error): #{err}", 1, self)

    # Do save the record
    ensure
      self.save
    end
  end



  # --- Screenshot Color Palette ---
  def process_color_palette!
    return false if self.screenshot_file_size.blank? || self.screenshot_file_size < 1

    color_palette = self.color_palette rescue nil
    color_palette ||= self.build_color_palette

    begin
      Timeout::timeout(60) do # 60 seconds
        img = Magick::ImageList.new
        _debug(self.screenshot.url(:original), 1, [self])

        img.from_blob(open(self.screenshot.url(:original), read_timeout: 5, "User-Agent" => CRAWLER_USER_AGENT).read)
        img.delete_profile('*')
        # primary = img.pixel_color(0,0)
        palette = img.quantize(10).color_histogram.sort{|a,b| b.last <=> a.last}
        primary = palette[0][0]

        color_palette.assign_attributes({
          dominant_color: [rgb(primary.red), rgb(primary.green), rgb(primary.blue)],
          dominant_color_red: rgb(primary.red),
          dominant_color_green: rgb(primary.blue),
          dominant_color_blue: rgb(primary.green),
          color_palette: palette.map{|p,c,r| [rgb(p.red), rgb(p.green), rgb(p.blue)]}
        })
        color_palette.save
      end

    rescue OpenURI::HTTPError => err
      _debug("Fetch Palette Error (OpenURI): #{err}", 1, self)
      false

    rescue Timeout::Error => err
      _debug("Fetch Palette Error (Timeout): #{err}", 1, self)
      false

    rescue => err
      _debug("Fetch Palette Error (Error): #{err}", 1, self)
      false
    end
      
  end

  # --- Screenshot Color Palette ---
  def process_pixel_color!
    return false if self.screenshot_file_size.blank? || self.screenshot_file_size < 1

    color_palette = self.color_palette rescue nil
    color_palette ||= self.build_color_palette

    begin
      Timeout::timeout(20) do # 20 seconds
        img = Magick::ImageList.new
        _debug(self.screenshot.url(:pixel), 1, [self])

        img.from_blob(open(self.screenshot.url(:pixel), read_timeout: 5, "User-Agent" => CRAWLER_USER_AGENT).read)
        img.delete_profile('*')
        primary = img.pixel_color(0,0)

        color_palette.assign_attributes({
          pixel_color: [rgb(primary.red), rgb(primary.green), rgb(primary.blue)],
          pixel_color_red: rgb(primary.red),
          pixel_color_green: rgb(primary.blue),
          pixel_color_blue: rgb(primary.green)
        })
        color_palette.save
      end

    rescue OpenURI::HTTPError => err
      _debug("Fetch Pixel Error (OpenURI): #{err}", 1, self)
      false

    rescue Timeout::Error => err
      _debug("Fetch Pixel Error (Timeout): #{err}", 1, self)
      false

    rescue => err
      _debug("Fetch Pixel Error (Error): #{err}", 1, self)
      false
    end
  end


protected

  def rgb(i=0)
    (@q18 || i > 255 ? ((255*i)/65535) : i).round
  end

end