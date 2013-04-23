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

['http://metafetch.com/chdfsfsejian/sdfsd', 'http://fffff.at/shaved-bieber', 'https://www.twitter.com/gleuch', 'http://www.xolator.com'].each do |u|
  _debug(u, 1)
  page = get_webpage(u)
end


_debug('...done!')

exit