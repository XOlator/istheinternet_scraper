# encoding: UTF-8

# START IT UP...
APP_MODE = 'scraper'
APP_ROOT = File.expand_path('..', File.dirname(__FILE__))
DEBUG = true
TIME_START = Time.now

require 'rubygems'
require 'bundler'

Bundler.require

require "#{APP_ROOT}/config.rb"

_heading("URL Queue Pusher")

# @history, @history_index = [], 0

thread = Thread.new {
  loop {
    _debug("")
    _debug("Enter a URL:")
    url = gets.chomp

    begin
      page = PageQueue.new(:url => url, :priority => 10)
      if page.save
        _debug("Added #{page.url} to queue",1)
      else
        _debug("Unable to add #{page.url} to queue (1)", 1)
      end
    rescue => err
      puts err.inspect
      _debug("Unable to add #{page.url} to queue (2)", 1)
    end
  }
}


# Kill threads upon kill command
trap("INT") do
  thread.exit
  _debug('...done!')
  exit
end

# Keep-alive
loop {
  thread.join(0.5)
}

exit