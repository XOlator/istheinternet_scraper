# Get base URL
def get_url_host(u)
  URI.parse(u).host.gsub(/^www\./, '').downcase
end

# Scrape website
def get_website(u)
  s = WebSite.find(get_url_host(u)) rescue nil
  s ||= WebSite.create(:url => u, :host_url => get_url_host(u))
  s.rescrape_robots_txt! if s.rescrape_robots_txt?
  s.rescrape_whois_record! if s.rescrape_whois_record?
  s
end