class WebSite < ActiveRecord::Base

  self.per_page = 50

  # Nicer fetching by url name
  extend FriendlyId
  friendly_id :host_url

  # File storage for DNS record
  include Paperclip::Glue
  has_attached_file :dns_file, 
    :path => ':rails_root/public/storage/web_sites/:attachment/:id_partition/:filename.:extension'
    # :default_url => 'https://popblock-assets.s3.amazonaws.com/user/missing/:attachment_:style.:extension',
    # :storage => :s3, :s3_credentials => "#{APP_ROOT}/s3.yml", 


  # --- Associations ----------------------------------------------------------

  has_many :web_pages
  # has_many :latest_web_pages, :through => :web_pages


  # --- Methods ---------------------------------------------------------------


  # Robots.txt methods
  def rescrape_robots_txt?
    !self.robots_txt_updated_at || (self.robots_txt_updated_at + 30.days) < Time.now
  end
  def robots_txt_url; URI.join(self.url, 'robots.txt'); end

  def rescrape_robots_txt!
    begin
      status = Timeout::timeout(15) do # 15 seconds
        io = open(self.robots_txt_url, :read_timeout => 15, "User-Agent" => CRAWLER_USER_AGENT)
        self.robots_txt = io.read
        self.robots_txt_updated_at = Time.now
        self.save
      end
    rescue Timeout::Error => err
      puts "Fetch Photo Error (Timeout): #{err}"
    rescue OpenURI::HTTPError => err
      puts "Fetch Photo Error (HTTPError): #{err}"
    rescue => err
      puts "Fetch Photo Error (Error): #{err}"
    end
  end

  # Rewritten from http://www.the-art-of-web.com/php/parse-robots/#.UW1_VCtARZ8
  def robots_txt_allow?(u, ua=CRAWLER_USER_AGENT)
    return true if self.robots_txt.blank?

    uri, agents, rules, ua_rules = URI.parse(u), Regexp.new("(.*)|(#{Regexp.escape(ua)})", Regexp::IGNORECASE), [], false

    self.robots_txt.each_line do |ln|
      next if ln.blank? || ln.match(/^\#/)
      ua_rules = Regexp.last_match.match(agents) if (ln.match(/^\s*User-agent:\s*(.*)/i))

      if ua_rules && ln.match(/^\s*Disallow:(.*)/i)
        return true unless Regexp.last_match.blank?
        rules << Regexp.new("^#{Regexp.last_match}", Regexp::IGNORECASE)
      end
    end

    rules.each{|rule| return false if uri.path.match(rule) }

    true
  end



protected

  

end