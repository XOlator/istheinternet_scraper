# Get base URL


def get_url_host(u)
  URI.parse(u).host.gsub(/^www\./, '').downcase
end