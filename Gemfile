if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

source 'https://rubygems.org'

gem 'rack',                     '1.5.2'
gem 'rake',                     '10.1.0'
gem 'mysql2',                   '0.3.13',     :require => false
gem 'activerecord',             '3.2.14'
gem 'rmagick',                  '2.13.2'
gem 'ruby-prof',                '0.13.0'
gem 'crack',                    '0.4.1'
gem 'json',                     '1.8.0'
gem 'oj',                       '2.1.4'
gem 'paperclip',                '3.5.1'
gem 'friendly_id',              '4.0.10.1'
gem 'addressable',              '2.3.5'
# gem 'pony',                     '1.4'
gem 'color',                    '1.4.2'

# Queue
gem 'sidekiq',                  '2.14.1'
gem 'sidekiq-middleware',       '0.1.4'

# Screenshot processing
gem 'selenium-webdriver',       '2.35.1',    :require => false

# API Intgrations
gem 'geocoder',                 '1.1.8'
gem 'aws-sdk',                  '1.17.0'
gem 'dnsruby',                  '1.54'
gem 'whois',                    '3.2.1'
gem 'twitter',                  '4.8.1',    :require => false

# Monitoring
# gem 'errplane',                 '0.6.7'

# ------------------------------------------------

# TESTING
group :test do
  gem 'rspec',                  '2.13.0'
  gem 'sqlite3',                '1.3.7'
  gem 'spork',                  '0.9.2'
  gem 'turn',                   '0.9.6',    :require => false
  gem 'simplecov',              '0.7.1',    :require => false
  gem 'timecop',                '0.6.1'
  gem 'webmock',                '1.11.0'
  gem 'factory_girl',           '4.2.0'
end