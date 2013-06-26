# encoding: UTF-8

# Wayback WiFi
# A X&O Lab Creative Project
# http://www.x-and-o.co/lab
#
# (C) 2013 X&O. All Rights Reserved
# License information: LICENSE.md


APP_ROOT = File.expand_path(File.dirname(__FILE__))

Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"

require "rubygems"
require "bundler"
Bundler.setup


require "#{APP_ROOT}/config.rb"
require 'optparse'
Dir.glob("#{APP_ROOT}/scripts/modules/*.rb").each{|r| require r}


# Ensure the proper options are set on start
parts, options = {}, {}

OptionParser.new do |opts|
  opts.banner = "Usage: app.rb [options]"
  # opts.on("--debug", "Debug Mode") {|v| DEBUG ||= true}
  opts.on("-d", "--daemon", "Daemon Mode") {|v| options[:daemon] = true}
  PageQueue::STEPS.each{|k,z|
    opts.on("--#{k}") {|v| parts[k] = (parts[k] || 0) + 1}
  }
end.parse!

# DEBUG ||= false
PageQueue::STEPS.each{|k,v| parts[k] = 1} if parts.blank?

puts parts.inspect


# --- QUEUE ---

result = Proc.new{|parts,opts|
  threads = []

  begin
    parts.each do |part,q|
      q ||= 1

      (1..q).each do |i|
        threads << Thread.new {
          Thread.current[:name] = "#{part}_#{i}"
          Thread.current[:info] = {:name => part, :number => i}

          begin
            mod = page_module_for_step(part.to_sym).new(page_module_attrs_for_step(part,i)) rescue nil
            mod.run if mod
          rescue => err
            _debug("Error: #{part}: #{err}")
          end
        }
        sleep(0.25) # Give each a second to spin up
      end
    end

  rescue => err
    puts "ERROR for Queue: #{err}"
  end


  # Kill threads upon kill command
  trap(0) do
    threads.each {|thread| thread.exit }
    _debug('...done0!')
  end

  trap(2) do
    threads.each {|thread| thread.exit }
    _debug('...done2!')
    exit
  end


  # sleep(5)
  # 
  # _subheading("Flush Page Queue")
  # TMP
  # PageQueue.unscoped.all.each {|p| p.destroy}
  # ['http://google.com', 'http://gleu.ch/about', 'http://xolator.com', 'http://www.giveinspiration.org'].each do |u|
  #   PageQueue.create(:url => u) rescue nil
  # end

  # Keep-alive
  while !threads.blank? do
    threads.each do |thread|
      thread.join(0.5)
    end
  end
}


# --- RUN QUEUE ---

begin
  if options[:daemon]
    puts "Forking process..."
    p = fork { sleep(2); result.call(parts, options) }
    sleep(2)
    s = Process.getpgid(p) rescue nil
    if s
      Process.detach(p)
      File.open('./scraper.pid', "w") {|f| f.write p}
      puts "   running as #{p}."
    else
      puts "   did not start"
    end

  else
    result.call(parts, options)
  end
rescue => err
  puts "ERROR: #{err}"
  err.backtrace.map{|l| puts "   #{l}"} if DEBUG
end
