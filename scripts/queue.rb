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
Dir.glob("#{APP_ROOT}/scripts/modules/*.rb").each{|r| require r}

parts, threads = ARGV, []
parts = PageQueue::STEPS if parts.blank?


_heading("Queue for #{parts.join(',')}")

begin
  parts.each do |part|
    q = 1
    q = 4 if part == :screenshot

    (1..q).each do |i|
      threads << Thread.new {
        Thread.current[:name] = "#{part}_#{i}"
        Thread.current[:info] = {:name => part, :number => i}

        begin
          mod = page_module_for_step(part.to_sym).new(page_module_attrs_for_step(part,i)) rescue nil
          mod.run if mod
        rescue => err
          _debug("Error: #{part}: #{err}")
        end
      }
      sleep(0.25) # Give each a second to spin up
    end
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


# sleep(5)
# 
# _subheading("Flush Page Queue")
# TMP
# PageQueue.unscoped.all.each {|p| p.destroy}
# ['http://google.com', 'http://gleu.ch/about', 'http://xolator.com', 'http://www.giveinspiration.org'].each do |u|
#   PageQueue.create(:url => u) rescue nil
# end


# Keep-alive
while !threads.blank? do
  threads.each do |thread|
    thread.join(0.5)
  end
end

exit