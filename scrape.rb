# encoding: UTF-8

# START IT UP...
APP_MODE = 'scraper'
APP_ROOT = File.expand_path(File.dirname(__FILE__))
DEBUG = true
TIME_START = Time.now

census_file = ARGV.shift

require 'rubygems'
require 'bundler'

Bundler.require

require "#{APP_ROOT}/config.rb"



_heading('Scraper')

_subheading("Parsing #{census_file}")

['http://www.google.com'].each do |u|
  site = WebSite.find(get_url_host(u)) rescue nil
  site ||= WebSite.create(:url => u, :host_url => get_url_host(u))

  puts site.inspect
  site.rescrape_robots_txt! if site.rescrape_robots_txt?

  puts site.robots_txt_allow?(URI.join(u, '/ads/preferences').to_s)
  
end


_debug('...done!')

exit