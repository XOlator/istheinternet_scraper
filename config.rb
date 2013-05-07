# encoding: UTF-8

Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"


# PRE-DEFINED VARS
TIME_START    ||= Time.now
TEXT_COL_LEN  ||= 80

APP_ROOT  ||= File.expand_path(File.dirname(__FILE__))
APP_ENV   ||= 'development'
APP_MODE  ||= 'webapp'
DEBUG     ||= false

CRAWLER_VERSION = '1.0'
CRAWLER_USER_AGENT = "WhatColor.IsTheInter.net/#{CRAWLER_VERSION} (http://whatcolor.istheinter.net)"


# REQUIRE MODULES/GEMS
%w{yaml oj crack json active_record RMagick paperclip friendly_id geocoder geocoder/models/active_record dnsruby whois will_paginate will_paginate/active_record}.each{|r| require r}

# INITIALIZERS
Dir.glob("#{APP_ROOT}/initializers/*.rb").each{|r| require r}

# CONFIG
APP_CONFIG = YAML::load(File.open("#{APP_ROOT}/config.yml"))[APP_ENV]

# SETUP DATABASE
# require 'pg'
require 'mysql2'
ActiveRecord::Base.establish_connection( YAML::load(File.open("#{APP_ROOT}/database.yml"))[APP_ENV] )

# REQUIRE DATABASE MODELS
Dir.glob("#{APP_ROOT}/models/*.rb").each{|r| require r}
Dir.glob("#{APP_ROOT}/helpers/*.rb").each{|r| require r}