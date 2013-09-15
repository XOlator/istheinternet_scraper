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

_heading(parts.map{|k,v| "#{k} : #{v}"}.join(" -- "))


@run_active = true

def spawn_thread(p,i)
  return false unless @run_active

  sleep(0.25) # Give each a second to spin up

  Thread.new {
    Thread.current[:name] = "#{p}_#{i}"
    Thread.current[:info] = {:name => p, :number => i}

    begin
      mod = page_module_for_step(p.to_sym).new(page_module_attrs_for_step(p,i)) rescue nil
      mod.run if mod
    rescue => err
      _error("Error: #{p}_#{i}: #{err}")
      puts err.backtrace.inspect
    end
  }
end

# --- QUEUE ---

result = Proc.new{|parts,opts|
  threads = []

  begin
    parts.each do |part,q|
      q ||= 1

      (1..q).each do |i|
        _subheading("Spawning thread: #{part}_#{i}...")
        threads << {:part => part, :i => i, :thread => spawn_thread(part,i)}
      end
    end

  rescue => err
    puts "ERROR for Queue: #{err}"
  end


  # Kill threads upon kill command
  trap(0) do
    begin
      @run_active = false
      threads.each {|thread| thread[:thread].exit }
    rescue => err
      _error(err)
    ensure
      @DB.close rescue nil
      _debug('...done0!')
    end
  end

  trap(2) do
    begin
      @run_active = false
      threads.each {|thread| thread[:thread].exit }
    rescue => err
      _error(err)
    ensure
      @DB.close rescue nil
      _debug('...done2!')
      exit
    end
  end

  # Keep-alive
  while !threads.blank? do
    threads.each_with_index do |thread, i|
      begin
        if thread[:thread].status.blank?
          thread[:thread].exit rescue nil
          _subheading("Respawning thread: #{thread[:part]}_#{thread[:i]}...")
          thread[i][:thread] = spawn_thread(thread[:part], thread[:i])
        else
          thread[:thread].join(0.5)
        end
      rescue
        _subheading("Respawning thread2: #{thread[:part]}_#{thread[:i]}...")
        threads[i][:thread] = spawn_thread(thread[:part], thread[:i])
      end
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
