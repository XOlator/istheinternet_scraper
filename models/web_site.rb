class WebSite < ActiveRecord::Base

  # self.per_page = 50

  # Nicer fetching by url name
  extend FriendlyId
  friendly_id :host_url

  # DNS Ruby & WHOIS
  include Dnsruby
  include Whois

  # Geo information for server
  extend Geocoder::Model::ActiveRecord
  geocoded_by :server_ip_address do |obj,results|
    if geo = results.first
      obj.server_geo_country  = geo.country_code
      obj.server_geo_region   = geo.state_code
      obj.server_geo_city     = geo.city
    end
  end

  # File storage for DNS record
  include Paperclip::Glue
  has_attached_file :whois_record, 
    :path => "#{APP_ROOT}/public/storage/web_sites/:attachment/:id_partition/:filename",
    :style => {:original => [:txt]}
    # :default_url => 'https://popblock-assets.s3.amazonaws.com/user/missing/:attachment_:style.:extension',
    # :storage => :s3, :s3_credentials => "#{APP_ROOT}/s3.yml", 


  # --- Associations ----------------------------------------------------------

  has_many :web_pages
  # has_many :latest_web_pages, :through => :web_pages


  # --- Validations -----------------------------------------------------------

  after_validation :geocode, :if => lambda{ |obj| !obj.server_ip_address.blank? && obj.server_ip_address_changed? }

  validates :url, :presence => true, :format => {:with => /\Ahttp/i}


  # --- Methods ---------------------------------------------------------------


  # -- Robots.txt methods ---
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
      puts "Fetch Robots.txt Error (Timeout): #{err}"
    rescue OpenURI::HTTPError => err
      if (err || '').to_s.match(/404/)
        self.robots_txt = ''
        self.robots_txt_updated_at = Time.now
        self.save
      else
        puts "Fetch Robots.txt Error (HTTPError): #{err}"
      end
    rescue => err
      puts "Fetch Robots.txt Error (Error): #{err}"
    end
  end

  # Rewritten from http://www.the-art-of-web.com/php/parse-robots/#.UW1_VCtARZ8
  def robots_txt_allow?(u, ua=CRAWLER_USER_AGENT)
    return true if self.robots_txt.blank? # Blank robots means there is not to disallow us from.

    uri, agents, allow_rules, disallow_rules, ua_rules = Addressable::URI.parse(u), Regexp.new("(\\*)|(#{Regexp.escape(ua)})", Regexp::IGNORECASE), [], [], false
    path = uri.path
    path << "?#{URI.escape(uri.query)}" unless uri.query.blank?

    self.robots_txt.each_line do |ln|
      next if ln.blank? || ln.match(/\A\#/)

      ua_rules = Regexp.last_match[1].match(agents) if ln.match(/\A\s*User-agent:\s*(.*)/i)
      next unless ua_rules

      if ln.match(/\A\s*Allow:\s*(.*)/i)
        return true if Regexp.last_match[1].blank?
        allow_rules << Regexp.new("^#{Regexp.escape(Regexp.last_match[1]).gsub(/\\\*/, '.*')}$", Regexp::IGNORECASE)
      elsif ln.match(/\A\s*Disallow:\s*(.*)/i)
        return true if Regexp.last_match[1].blank?
        disallow_rules << Regexp.new("^#{Regexp.escape(Regexp.last_match[1]).gsub(/\\\*/, '.*')}$", Regexp::IGNORECASE)
      end
    end

    allow_rules.each{|rule| return true if path.match(rule) } # Check if passes Allow rule
    disallow_rules.each{|rule| return false if path.match(rule) } # Check if fails Disallow rule
    true # Otherwise, passes allows
  end
  alias_method :allow?, :robots_txt_allow?


  # -- WHOIS Record ---
  def rescrape_whois_record?
    !self.whois_record_updated_at || (self.whois_record_updated_at + 90.days) < Time.now
  end

  def rescrape_whois_record!
    begin
      status = Timeout::timeout(15) do # 15 seconds
        c = Whois.whois(self.host_url)
        s = StringIO.open(c.to_s)
        s.class_eval { attr_accessor :original_filename, :content_type }
        s.original_filename = "#{self.host_url}"
        self.whois_record = s

        self.domain_created_on = c.created_on
        self.domain_updated_on = c.updated_on
        self.domain_expires_on = c.expires_on

        self.nameservers = c.nameservers.map{|c| c.name}.join(',')

        c.nameservers.each do |ns|
          self.server_ip_address = Resolv.new.getaddress(ns.name) rescue nil
          break unless self.server_ip_address.blank?
        end

        self.save
      end
    rescue Timeout::Error => err
      puts "Fetch DNS Record Error (Timeout): #{err}"
    rescue => err
      puts "Fetch DNS Record Error (Error): #{err}"
    end
  end


protected
  

end