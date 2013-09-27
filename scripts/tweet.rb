# encoding: UTF-8

# A X&O Lab Creative Project
# http://www.x-and-o.co/lab
#
# (C) 2013 X&O. All Rights Reserved
# License information: LICENSE.md


# START IT UP...
APP_MODE = 'tweeter'
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
%w{yaml active_record twitter RMagick geocoder geocoder/models/active_record}.each{|r| require r}

# INITIALIZERS
Dir.glob("#{APP_ROOT}/initializers/*.rb").each{|r| require r}

# CONFIG
APP_CONFIG = YAML::load(File.open("#{APP_ROOT}/config.yml"))[APP_ENV]
TWEET_CONFIG = YAML::load(File.open("#{APP_ROOT}/twitter.yml"))[APP_ENV]

# SETUP DATABASE
# require 'pg'
require 'mysql2'
@DB = ActiveRecord::Base.establish_connection( YAML::load(File.open("#{APP_ROOT}/database.yml"))[APP_ENV] )

begin
  # REQUIRE DATABASE MODELS
  Dir.glob("#{APP_ROOT}/models/*.rb").each{|r| require r}
  Dir.glob("#{APP_ROOT}/helpers/*.rb").each{|r| require r}


  # SETUP TWITTER
  client = Twitter.configure do |config|
    config.consumer_key = TWEET_CONFIG['consumer_token']
    config.consumer_secret = TWEET_CONFIG['consumer_secret']
    config.oauth_token = TWEET_CONFIG['access_token']
    config.oauth_token_secret = TWEET_CONFIG['access_secret']
  end


  ct, pixel_hex_color, dom_hex_color, hsl_hex_color, color_name = ColorPalette.count, ColorPalette.pixel_hex_color, ColorPalette.dominant_hex_color, nil, ''
  str = "After #{number_to_delimiter(ct)} results, the average color of the Internet is ##{pixel_hex_color}. (Dominant average: ##{dom_hex_color}.)"
  # HSL average: ##{hsl_hex_color})"
  # (#{color_name})."
  puts str

  r,g,b = ColorPalette.pixel_rgb.map{|v| Magick::QuantumDepth > 8 ? ((v * Magick::QuantumRange) / 255.to_f) : v}

  ip = Magick::Image.new(1000,1000) { self.background_color = Magick::Pixel.new(r,g,b) }
  fp = Tempfile.new(["#{pixel_hex_color}_profile",'.png'])
  ip.write(fp.path)

  ib = Magick::Image.new(1252,626) { self.background_color = Magick::Pixel.new(r,g,b) }
  fb = Tempfile.new(["#{pixel_hex_color}_banner",'.png'])
  ib.write(fb.path)

  client.update_profile_colors(profile_background_color: pixel_hex_color)
  client.update_profile_image(fp)
  client.update_profile_banner(fb)
  client.update(str)

rescue => err
  _error(err)

ensure
  ActiveRecord::Base.connection.close
end