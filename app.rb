# encoding: UTF-8

# A X&O Lab Creative Project
# http://www.x-and-o.co/lab
#
# (C) 2013 X&O. All Rights Reserved
# License information: LICENSE.md


# START IT UP...
APP_MODE = 'scraper'
APP_ROOT = File.expand_path('.', File.dirname(__FILE__))
DEBUG = true
TIME_START = Time.now

require "rubygems"
require "bundler"
Bundler.require

require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'whatcolor', :url => 'redis://localhost:6379/1' }
end

Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'whatcolor', :url => 'redis://localhost:6379/1' }
end



require "#{APP_ROOT}/config.rb"
Dir.glob("#{APP_ROOT}/scripts/modules/*.rb").each{|r| require r}

# Add into Sidekiq Queue
def queue(url,force=[])
  IsTheInternet::Page::Capture.perform_async(url,force)
end