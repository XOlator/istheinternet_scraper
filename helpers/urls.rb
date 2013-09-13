# Get base URL
def get_url_path(u)
  i = Addressable::URI.parse(u)
  p = (i.path || '').downcase rescue ''
  p << "?#{i.query}" unless i.query.blank?
  p << "##{i.fragment}" unless i.fragment.blank?
  return (p.blank? ? "/" : p)
end

# Get URL path
def get_url_host(u)
  Addressable::URI.parse(u).host.gsub(/\Awww\./, '').downcase
end

# Scrape website
def get_website(u)
  s = WebSite.find(get_url_host(u)) rescue nil
  s ||= WebSite.create(:url => u, :host_url => get_url_host(u))
  s.rescrape_robots_txt! if s.rescrape_robots_txt?
  s.rescrape_whois_record! if s.rescrape_whois_record?
  s
end

# Scrape webpage
def get_webpage(u)
  q, s = get_url_path(u), get_website(u)
  return false unless s.allow?(u)

  p = s.web_pages.find_by_path(q) rescue nil
  p ||= WebPage.create(:path => q, :web_site_id => s.id, :url => u)

  # Scrape and store web page
  p.rescrape!# if p.rescrape?

  p
end