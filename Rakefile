require "bundler/setup"

require './config.rb'
# require 'sinatra/activerecord/rake'

# Require models
Dir.glob("#{APP_ROOT}/models/*.rb").each{|r| require r}


namespace :db do
  # def create_database config
  #   options = {:charset => 'utf8', :collation => 'utf8_unicode_ci'}
  #  
  #   create_db = lambda do |config|
  #     ActiveRecord::Base.establish_connection config.merge('database' => nil)
  #     ActiveRecord::Base.connection.create_database config['database'], options
  #     ActiveRecord::Base.establish_connection config
  #   end
  #  
  #   begin
  #     create_db.call config
  #   rescue Mysql::Error => sqlerr
  #     if sqlerr.errno == 1405
  #       print "#{sqlerr.error}. \nPlease provide the root password for your mysql installation\n>"
  #       root_password = $stdin.gets.strip
  #  
  #       grant_statement = <<-SQL
  #         GRANT ALL PRIVILEGES ON #{config['database']}.* 
  #           TO '#{config['username']}'@'localhost'
  #           IDENTIFIED BY '#{config['password']}' WITH GRANT OPTION;
  #       SQL
  #  
  #       create_db.call config.merge('database' => nil, 'username' => 'root', 'password' => root_password)
  #     else
  #       $stderr.puts sqlerr.error
  #       $stderr.puts "Couldn't create database for #{config.inspect}, charset: utf8, collation: utf8_unicode_ci"
  #       $stderr.puts "(if you set the charset manually, make sure you have a matching collation)" if config['charset']
  #     end
  #   end
  # end
 
  task :environment do
    DATABASE_ENV = ENV['DATABASE_ENV'] || 'scraper'
    MIGRATIONS_DIR = ENV['MIGRATIONS_DIR'] || 'db/migrate'
  end
 
  task :configuration => :environment do
    @config = YAML.load_file('database.yml')[DATABASE_ENV]
  end
 
  task :configure_connection => :configuration do
    ActiveRecord::Base.establish_connection @config
    ActiveRecord::Base.logger = Logger.new STDOUT if @config['logger']
  end
 
  # desc 'Create the database from config/database.yml for the current DATABASE_ENV'
  # task :create => :configure_connection do
  #   create_database @config
  # end
 
  # desc 'Drops the database for the current DATABASE_ENV'
  # task :drop => :configure_connection do
  #   ActiveRecord::Base.connection.drop_database @config['database']
  # end
 
  desc 'Migrate the database (options: VERSION=x, VERBOSE=false).'
  task :migrate => :configure_connection do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate MIGRATIONS_DIR, ENV['VERSION'] ? ENV['VERSION'].to_i : nil
  end
 
  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback => :configure_connection do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.rollback MIGRATIONS_DIR, step
  end
 
  desc "Retrieves the current schema version number"
  task :version => :configure_connection do
    puts "Current version: #{ActiveRecord::Migrator.current_version}"
  end
end


namespace :colors do
  task :process do
    ColorPalette.order('web_page_id asc').where('updated_at < ?', (Time.now-12.hours)).all.each do |c|
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
end

namespace :paperclip do
  task :permissions do
    require 'aws/s3'

    # Load credentials
    s3_options = YAML.load_file(File.join(APP_ROOT, 's3.yml'))[APP_ENV].symbolize_keys
    bn = s3_options[:bucket]

    # Establish S3 connection
    s3_options.delete(:bucket_name)
    s3 = AWS::S3.new(s3_options)
    b = s3.buckets[bn]

    wp_s = [:original]
    wp_ct = WebPage.count
    WebPage.first.screenshot.styles.each{|s| wp_s.push(s[0]) }

    WebPage.all.each_with_index do |a, n|
      wp_s.each do |s|
        p = a.screenshot.path(s)
        ps = p.gsub(/(\.[A-Z]+)$/i, "/#{a.id}\\1")

        begin
          obj = b.objects[ps]
          if obj.exists?
            obj2 = obj.move_to(p)
            obj2.acl = :public_read
            puts "Moved #{ps} => #{p}"
          end
        rescue => e
          puts "Error 2: #{e}"
        end
      end unless a.screenshot_file_size.blank?
    end
  end

  task :migrate do
    require 'aws/s3'
    
    # Load credentials
    s3_options = YAML.load_file(File.join(APP_ROOT, 's3.yml'))[APP_ENV].symbolize_keys
    bn = s3_options[:bucket]
    
    # Establish S3 connection
    s3_options.delete(:bucket_name)
    s3 = AWS::S3.new(s3_options)
    b = s3.buckets[bn]

    ws_w, wp_s, wp_p = [:original], [:original], [:original]
    ws_ct, wp_ct = WebSite.count, WebPage.count
    WebPage.first.screenshot.styles.each{|s| wp_s.push(s[0])}
    
    WebPage.all.each_with_index do |a, n|
      # wp_s.each do |s|
      #   p = a.screenshot.path(s)
      #   u = a.screenshot.url(s).gsub(/^\//, '').gsub(/(\?.*)$/, '')
      # 
      #   begin
      #     obj = b.objects.create(u, '')
      #     raise "#{p}" unless obj.write(:file => p, :access => :public_read)
      #     puts "Saved #{p} to S3 (#{n}/#{wp_ct})"
      #   rescue => e
      #     puts "Error 1: #{e}"
      #   end
      # end unless a.screenshot_file_size.blank?

      wp_p.each do |s|
        p = a.html_page.path(s)
        u = a.html_page.url(s).gsub(/^\//, '').gsub(/(\?.*)$/, '')

        begin
          obj = b.objects.create(u, '')
          raise "#{p}" unless obj.write(:file => p, :access => :public_read)
          puts "Saved wphtml #{p} to S3 (#{n}/#{wp_ct})"
        rescue => e
          puts "Error 2: #{e}"
        end
      end unless a.html_page_file_size.blank?
    end

    WebSite.all.each_with_index do |a, n|
      ws_w.each do |s|
        p = a.whois_record.path(s)
        u = a.whois_record.url(s).gsub(/^\//, '')
        
        begin
          obj = b.objects.create(u, '')
          raise "#{p}" unless obj.write(:file => p, :access => :public_read)
          puts "Saved ws #{p} to S3 (#{n}/#{ws_ct})"
        rescue => e
          puts "Error 3: #{e}"
        end
      end unless a.whois_record_file_size.blank?
    end
  end
end
