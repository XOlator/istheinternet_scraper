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


require "headless"
require "selenium-webdriver"


_subheading('Screenshot Generation')

Headless.ly do |h|
  @driver = Selenium::WebDriver.for(:chrome)

  begin
    loop {
      page = PageQueue.screenshot.first rescue nil

      # Process if something is found
      unless page.blank?
        begin
          page.lock!

          fname = "#{APP_ROOT}/tmp/#{page.web_page.id}.jpg"
          _debug(page.web_page.base_uri)

          @driver.navigate.to(page.web_page.base_uri)
          # TODO : Inject script to check if window loaded, timeout after 15 seconds
          sleep(5)
          @driver.save_screenshot(fname)
          page.web_page.screenshot = open(fname)

          # If screenshot was saved, then mark as completed
          if page.web_page.save
            page.step!(:screenshot)
          else
            page.retry!
          end

        rescue => err
          _debug("ERROR: #{err}", 1)
          page.retry!

        ensure
          File.unlink(fname) rescue nil
          page.unlock! rescue nil
        end

      # Nothing in queue. Pause for a few seconds
      else
        _debug('.')
        sleep(5)
      end
    }

  rescue => err
    _debug("ERROR: #{err}")

  ensure
    @driver.quit rescue nil
  end
end



_debug('...done!')

exit