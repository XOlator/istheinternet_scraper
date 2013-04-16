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

['http://www.google.com', 'http://www.facebook.com', 'https://www.twitter.com', 'http://www.xolator.com'].each do |u|
  # _debug(u, 1)
  site = get_website(u)
  # _debug(site.allow?(URI.join(u, '/ads').to_s), 2)
end


_debug('...done!')

exit