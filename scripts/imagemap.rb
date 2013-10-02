# encoding: UTF-8

# A X&O Lab Creative Project
# http://www.x-and-o.co/lab
#
# (C) 2013 X&O. All Rights Reserved
# License information: LICENSE.md


# START IT UP...
APP_MODE = 'imagemap'
APP_ROOT = File.expand_path('..', File.dirname(__FILE__))
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
%w{yaml active_record geocoder RMagick geocoder/models/active_record}.each{|r| require r}

# INITIALIZERS
Dir.glob("#{APP_ROOT}/initializers/*.rb").each{|r| require r}

# CONFIG
APP_CONFIG = YAML::load(File.open("#{APP_ROOT}/config.yml"))[APP_ENV]
TWEET_CONFIG = YAML::load(File.open("#{APP_ROOT}/twitter.yml"))[APP_ENV]

# SETUP DATABASE
require 'mysql2'
@DB = ActiveRecord::Base.establish_connection( YAML::load(File.open("#{APP_ROOT}/database.yml"))[APP_ENV] )


begin
  # REQUIRE DATABASE MODELS
  Dir.glob("#{APP_ROOT}/models/*.rb").each{|r| require r}
  Dir.glob("#{APP_ROOT}/helpers/*.rb").each{|r| require r}

  # How much to scale the image (how large of an area should each palette be)
  scale = ENV['COLORMAP_SCALE'].to_i rescue 1
  scale = 1 if scale.blank?

  # Counts/Math
  ct, cts, maxct, i = ColorPalette.has_pixel_color.count, 0, 0, 0
  cts = Math.sqrt(ct).round
  maxct, maxctz = cts*cts, (cts*scale)*(cts*scale)

  _debug("Making image #{cts * scale}x#{cts * scale} (#{scale}x)")

  img = Magick::Image.new(cts*scale,cts*scale) { self.background_color = 'white'}

  obj = ColorPalette.has_pixel_color
  # obj = obj.order('created_at DESC') #.order('RAND()')
  obj = obj.joins(:web_page).order('web_pages.url ASC') #.order('pixel_color_red DESC')
  obj = obj.limit(maxct)
  obj.each do |c|
    next if c.blank?
    # puts c.web_page.inspect; next
    gc = Magick::Draw.new
    x1,y1 = (i % cts)*scale, (i/cts.to_f).floor*scale
    x2,y2 = x1+scale, y1+scale
    gc.fill("#" << c.pixel_hex_color)
    gc.polygon(x1,y1,x1,y2,x2,y2,x2,y1)
    gc.draw(img)
    i += 1
    break if i >= maxct
  end

  img.write(File.join(APP_ROOT, 'tmp', "colormap_#{Time.now.to_i}.png"))


rescue => err
  _error(err)
ensure
  ActiveRecord::Base.connection.close
end
