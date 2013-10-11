require "bundler/setup"

require './config.rb'
# require 'sinatra/activerecord/rake'

# Require models
Dir.glob("#{APP_ROOT}/models/*.rb").each{|r| require r}


namespace :counters do
  task :reset do
    WebSite.all.each do |w|
      WebSite.reset_counters(w.id, :web_pages)
      w.update_attribute(:completed_web_pages_count, w.web_pages.complete?.count)
    end
  end
end

# namespace :storage do
#   task :to_s3 do
#     require 'aws/s3'
#     s3_options = YAML.load_file(File.join(APP_ROOT, 's3.yml'))[APP_ENV].symbolize_keys
#     bn = s3_options[:bucket]
# 
#     # Establish S3 connection
#     s3_options.delete(:bucket_name)
#     s3 = AWS::S3.new(s3_options)
#     b = s3.buckets[bn]
# 
#     puts "HTML_PAGES\n\n"
#     Dir.glob("#{APP_ROOT}/storage/web_pages/html_pages/*/*/*/*/*").each{|r| 
#       begin
#         u = r.gsub("#{APP_ROOT}/", '')
#         if b.objects[u].exists?
#           puts "Exists: #{u}"
#           b.objects[u].acl = :public_read
#           next
#         end
#         puts u
#         obj = b.objects.create(u, '')
#         raise "#{p}" unless obj.write(:file => r, :access => :public_read)
#         obj.acl = :public_read
#       rescue => e
#         puts "> Error: #{e}"
#       end
#     }
# 
#     puts "\n\n\nSCREENSHOTS\n\n"
#     Dir.glob("#{APP_ROOT}/storage/web_pages/screenshots/*/*/*/*").each{|r|
#       begin
#         u = r.gsub("#{APP_ROOT}/", '')
#         if b.objects[u].exists?
#           puts "Exists: #{u}"
#           b.objects[u].acl = :public_read
#           next
#         end
#         puts u
#         obj = b.objects.create(u, '')
#         raise "#{p}" unless obj.write(:file => r, :access => :public_read)
#         obj.acl = :public_read
#       rescue => e
#         puts "> Error: #{e}"
#       end
#     }
#   end
# end

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

