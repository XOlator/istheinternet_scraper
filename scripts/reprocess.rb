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
require "#{APP_ROOT}/config.rb"


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


    ColorPalette.where('updated_at < ?', (Time.now-72.hours)).find_in_batches(:batch_size => 10) do |g|
      g.each do |c|
        next if c.blank?
        next if [14770].include?(c.id)
        _debug("Process ##{c.web_page.id} - ##{c.id}", 0, [c.web_page])
        begin
          if c.web_page.process_color_palette!
            _debug(c.web_page.color_palette.dominant_color.inspect, 1, [c.web_page.color_palette])
            _debug("...done!", 1, [c.web_page])
          else
            _debug("...error!", 1, [c.web_page])
          end
        rescue => err
          _debug(err, 1, [c.web_page])
        end
      end
    end


rescue => err
  _error(err)
ensure
  ActiveRecord::Base.connection.close
end
