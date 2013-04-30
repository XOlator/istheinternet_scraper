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


parts, threads = ARGV, []
parts = PageQueue::STEPS if parts.blank?

_heading("Queue for #{parts.join(',')}")

begin
  parts.each do |part|
    threads << Thread.new {
      Thread.current[:name] = part
      begin
        require "#{APP_ROOT}/scripts/components/#{part}.rb" if File.exists?("#{APP_ROOT}/scripts/components/#{part}.rb")
      rescue => err
        puts "Thread error #{part}: #{err}"
        raise err
      end
    }

    sleep(1) # Give each a second to spin up
  end

rescue => err
  puts "ERROR for Queue: #{err}"
end


# Kill threads upon kill command
trap("INT") do
  threads.each {|thread| thread.exit }
  _debug('...done!')
  exit
end


sleep(15)

_subheading("Flush Page Queue")
# TMP
PageQueue.unscoped.all.each {|p| p.destroy}
['http://google.com', 'http://gleu.ch/about', 'http://xolator.com', 'http://www.giveinspiration.org'].each do |u|
  PageQueue.create(:url => u) rescue nil
end


# Keep-alive
while !threads.blank? do
  threads.each do |thread|
    thread.join(0.5)
  end
end

exit