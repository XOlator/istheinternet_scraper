# encoding: UTF-8

# A X&O Lab Creative Project
# http://www.x-and-o.co/lab
#
# (C) 2014 X&O. All Rights Reserved
# License information: LICENSE.md


# START IT UP...
APP_MODE = 'alphabet'
APP_ROOT = File.expand_path('../..', File.dirname(__FILE__))
DEBUG = true
TIME_START = Time.now

require "rubygems"
require "bundler"
Bundler.require

# encoding: UTF-8

Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"


# PRE-DEFINED VARS
TIME_START    ||= Time.now
TEXT_COL_LEN  ||= 80

APP_ENV   ||= 'development'


CRAWLER_VERSION = '1.0'
CRAWLER_USER_AGENT = "WhatColor.IsTheInter.net/#{CRAWLER_VERSION} (http://whatcolor.istheinter.net)"


# REQUIRE MODULES/GEMS
%w{yaml active_record RMagick geocoder geocoder/models/active_record}.each{|r| require r}

# INITIALIZERS
Dir.glob("#{APP_ROOT}/initializers/*.rb").each{|r| require r}

# CONFIG
APP_CONFIG = YAML::load(File.open("#{APP_ROOT}/config.yml"))[APP_ENV]


# SETUP DATABASE
# require 'pg'
require 'mysql2'
@DB = ActiveRecord::Base.establish_connection( YAML::load(File.open("#{APP_ROOT}/database.yml"))[APP_ENV] )

begin
  # REQUIRE DATABASE MODELS
  Dir.glob("#{APP_ROOT}/models/*.rb").each{|r| require r}
  Dir.glob("#{APP_ROOT}/helpers/*.rb").each{|r| require r}


  sleep 5

  puts "","Alphabet","-"*80
  %w(a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 0).each do |v|
    obj = ColorPalette.where(web_page_id: WebPage.where(web_site_id: WebSite.where('url LIKE ? OR url LIKE ? OR url LIKE ? OR url LIKE ?', "https://www.#{v}%", "https://#{v}%", "http://www.#{v}%", "http://#{v}%").pluck(:id) ) )
    color = obj.pixel_rgb
    puts [v, obj.count, ("%02x%02x%02x" % color).upcase, '', color.map(&:round).join(', ')].join("\t")
  end

  puts "","","HTTP v HTTPS","-"*80
  %w(http https).each do |v|
    obj = ColorPalette.where(web_page_id: WebPage.where(web_site_id: WebSite.where('url LIKE ?', "#{v}%").pluck(:id) ) )
    color = obj.pixel_rgb
    puts [v, obj.count, ("%02x%02x%02x" % color).upcase, '', color.map(&:round).join(', ')].join("\t")
  end

  puts "","","WWW. vs NOT","-"*80
  [true,false].each do |v|
    if v
      ws = WebSite.where('url LIKE ? OR url LIKE ?', "https://www.%", "http://www.%")
    else
      ws = WebSite.where('not(url LIKE ? OR url LIKE ?)', "https://www.%", "http://www.%")
    end

    obj = ColorPalette.where(web_page_id: WebPage.where(web_site_id: ws.pluck(:id) ) )
    color = obj.pixel_rgb
    puts [v ? 'WWW.' : 'NOT', obj.count, ("%02x%02x%02x" % color).upcase, '', color.map(&:round).join(', ')].join("\t")
  end

rescue => err
  _error(err)

ensure
  ActiveRecord::Base.connection.close
end