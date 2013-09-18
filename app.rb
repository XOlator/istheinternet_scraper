# encoding: UTF-8

# A X&O Lab Creative Project
# http://www.x-and-o.co/lab
#
# (C) 2013 X&O. All Rights Reserved
# License information: LICENSE.md


# START IT UP...
APP_MODE = 'scraper'
APP_ROOT = File.expand_path('.', File.dirname(__FILE__))
DEBUG = true
TIME_START = Time.now

require "rubygems"
require "bundler"
Bundler.require


require "#{APP_ROOT}/config.rb"
# require 'optparse'
Dir.glob("#{APP_ROOT}/scripts/modules/*.rb").each{|r| require r}


# Ensure the proper options are set on start
# parts, options = {}, {}
# 
# OptionParser.new do |opts|
#   opts.banner = "Usage: app.rb [options]"
#   # opts.on("--debug", "Debug Mode") {|v| DEBUG ||= true}
#   opts.on("-d", "--daemon", "Daemon Mode") {|v| options[:daemon] = true}
#   PageQueue::STEPS.each{|k,z|
#     opts.on("--#{k}") {|v| parts[k] = (parts[k] || 0) + 1}
#   }
# end.parse!

# # DEBUG ||= false
# PageQueue::STEPS.each{|k,v| parts[k] = 1} if parts.blank?
# 
# puts parts.inspect



IsTheInternet::Page::Capture.new('http://xolator.com')



# # --- QUEUE ---
# 
# result = Proc.new{|parts,opts|
# 
# }
# 
# 
# # --- RUN QUEUE ---
# 
# begin
#   if options[:daemon]
#     puts "Forking process..."
#     p = fork { sleep(2); result.call(parts, options) }
#     sleep(2)
#     s = Process.getpgid(p) rescue nil
#     if s
#       Process.detach(p)
#       File.open('./scraper.pid', "w") {|f| f.write p}
#       puts "   running as #{p}."
#     else
#       puts "   did not start"
#     end
# 
#   else
#     result.call(parts, options)
#   end
# rescue => err
#   puts "ERROR: #{err}"
#   err.backtrace.map{|l| puts "   #{l}"} if DEBUG
# end
