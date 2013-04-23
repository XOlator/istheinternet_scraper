# encoding: UTF-8

# START IT UP...
APP_MODE = 'scraper'
APP_ROOT = File.expand_path(File.dirname(__FILE__))
DEBUG = true
TIME_START = Time.now

census_file = ARGV.shift

require 'rubygems'
require 'bundler'

Bundler.require

require "#{APP_ROOT}/config.rb"


require "headless"
require "selenium-webdriver"


_heading('Screenshot Generation')

Headless.ly do |h|
  d = Selenium::WebDriver.for(:chrome)

  begin
    WebPage.available.each do |p|
      f = "tmp/#{p.id}.jpg"
      _debug(p.url, 1)

      begin
        d.navigate.to(p.base_uri)
        # TODO : Inject script to check if window loaded, timeout after 15 seconds
        sleep(5)
        d.save_screenshot(f)
        p.screenshot = open(f)

      rescue => err
        puts "ERROR Screenshot: #{err}"

      ensure
        File.unlink(f) rescue nil
      end
    end

  rescue => err
    puts "ERROR: #{err}"

  ensure
    d.quit rescue nil
  end
end




_debug('...done!')

exit