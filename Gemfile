if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

source 'https://rubygems.org'

gem 'rack',                     '1.5.2'
gem 'rake',                     '10.0.4'
gem 'mysql2',                   '0.3.11',     :require => false
gem 'pg',                       '0.15.1'
gem 'activerecord',             '3.2.13'
gem 'rmagick',                  '2.13.2'
gem 'crack',                    '0.3.2'
gem 'json',                     '1.7.7'
gem 'oj',                       '2.0.10'
gem 'will_paginate',            '3.0.4'
gem 'paperclip',                '3.4.1'
gem 'friendly_id',              '4.0.9'
# gem 'pony',                     '1.4'

# Screenshot processing
gem 'selenium-webdriver',       '2.32.1'

# API Intgrations
gem 'geocoder',                 '1.1.6'
gem 'aws-sdk',                  '1.8.5'
gem 'dnsruby',                  '1.53'
gem 'whois',                    '3.1.1'

# Monitoring
gem 'errplane',                 '0.6.7'

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