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


_subheading('Web Page Scraper')

# begin
  loop {
    page = PageQueue.scrape.first rescue nil

    # Process if something is found
    unless page.blank?
      begin
        page.lock!

        _debug("Scraping #{page.url}")
        web_page = get_webpage(page.url)

        unless web_page.blank?
          page.web_page = web_page
          
          if page.save && web_page.scraped?
            page.step!(:scrape)
            _debug("...scraping done", 1)

          else
            page.retry!
            _debug("...scraping error. Retrying again shortly.", 1)
          end

        # Web page does not exists or is not scrapable -- remove from queue
        else
          page.destroy rescue nil
          _debug("...unable to scrape.", 1)
        end

      rescue => err
        _debug("Scrape Error: #{err}", 1)
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