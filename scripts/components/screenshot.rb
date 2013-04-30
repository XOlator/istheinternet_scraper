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

begin
  @headless = Headless.new
  @headless.start

  begin
    @driver = Selenium::WebDriver.for(:chrome)

    loop {
      page = PageQueue.screenshot.first rescue nil

      # Process if something is found
      unless page.blank?
        _debug("Screenshot #{page.url}")

        begin
          page.lock!

          fname = "#{APP_ROOT}/tmp/#{page.web_page.id}.jpg"

          @driver.navigate.to(page.web_page.base_uri)
          # TODO : Inject script to check if window loaded, timeout after 15 seconds
          sleep(5)
          @driver.save_screenshot(fname)
          page.web_page.screenshot = open(fname)
          @driver.navigate.to('about:blank')

          # If screenshot was saved, then mark as completed
          if page.web_page.save
            page.step!(:screenshot)
          else
            page.retry!
          end

          _debug("...screenshot done", 1)

        rescue => err
          _debug("Screenshot Error (1): #{err}", 1)
          page.retry!

        ensure
          File.unlink(fname) rescue nil
          page.unlock! rescue nil
        end

      # Nothing in queue. Pause for a few seconds
      else
        # _debug('.')
        sleep(5)
      end
    }

  rescue => err
    _debug("Screenshot Error (2): #{err}")

  ensure
    @driver.quit rescue nil
  end

  # Kill threads upon kill command
  trap("INT") do
    @driver.quit rescue nil
    @headless.destroy rescue nil
    exit
  end


rescue => err
  _debug("Screeshot Error (3): #{err}")

ensure
  @headless.destroy rescue nil
end



_debug('...done!')

exit