# encoding: UTF-8

# START IT UP...
APP_MODE = 'scraper'
APP_ROOT = File.expand_path('..', File.dirname(__FILE__))
DEBUG = true
TIME_START = Time.now

part = ARGV.shift

require 'rubygems'
require 'bundler'

Bundler.require

require "#{APP_ROOT}/config.rb"



_heading("Queue for #{part}")

begin
  require "#{APP_ROOT}/scripts/#{part}.rb"

rescue => err
  puts "ERROR for #{part} Queue: #{err}"
end

_debug('...done!')

exit