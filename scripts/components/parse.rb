# encoding: UTF-8

# # START IT UP...
# APP_MODE = 'scraper'
# APP_ROOT = File.expand_path(File.dirname(__FILE__))
# DEBUG = true
# TIME_START = Time.now
# 
# require 'rubygems'
# require 'bundler'
# 
# Bundler.require
# 
# require "#{APP_ROOT}/config.rb"


_subheading('Web Page Parser')

# TMP

# begin
  loop {
    page = PageQueue.parse.first rescue nil

    # Process if something is found
    unless page.blank?
      begin
        page.lock!

        _debug("Parsing #{page.url}")

        # NO PARSER YET, RUN THROUGH
        page.step!(:parse)

        _debug("...parsing done", 1)

      rescue => err
        _debug("Parse error: #{err}", 1)
        page.retry!
      
      ensure
        page.unlock! rescue nil
      end

    # Nothing in queue. Pause for a few seconds
    else
      # _debug('.')
      sleep(5)
    end
  }

# rescue => err
#   _debug("ERROR: #{err}")
# end

_debug('...done!')

exit