def next?
  File.basename(__FILE__) == "Gemfile.next"
end
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

if ENV['RUBY_BUILD'] == '3.1.0'
  # production/bleeding-edge ruby version
  ruby '3.1.7'
elsif ENV['RUBY_BUILD'] == '2.7.8'
  # development/develop ruby version
  ruby '2.7.8'
else
  # production/stable ruby version
  ruby '2.6.6'
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
if next?
  gem 'rails', '~> 7.0.0'
else
  gem 'rails', '~> 6.1.5'
end
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use Puma as the app server
if next?
  gem 'puma', '~> 5.6'
else
  gem 'puma', '~> 5.6'
end
# Use SCSS for stylesheets
if next?
  gem 'sassc-rails', '>= 2.1.1'
else
  gem 'sass-rails', '>= 6'
end
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
if next?
  # Use jsbundling-rails for Rails 7
  gem 'jsbundling-rails'
else
  gem 'webpacker', '~> 5.0'
end
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
gem 'image_processing', '~> 1.12'

if next?
  gem 'ros-apartment', '~> 3.0', require: 'apartment'
else
  gem 'ros-apartment', require: 'apartment'
end
gem 'ros-apartment-sidekiq', require: 'apartment-sidekiq'
gem 'apartment-activejob'
gem 'devise'
gem "comfortable_mexican_sofa",git: 'https://github.com/restarone/comfortable-mexican-sofa', tag: '3.5'
gem "comfy_blog", git: 'https://github.com/restarone/comfy-blog', branch: 'master'
gem 'simple_discussion', git: 'https://github.com/restarone/simple_discussion', branch: 'master'
gem 'gravatar_image_tag'
gem 'wicked' # for multi-step forms
gem 'devise_invitable'
gem "aws-sdk-s3", require: false
if next?
  gem 'meta-tags', '~> 2.20'
else
  gem 'meta-tags'
end
gem 'sitemap_generator'
gem 'ahoy_matey'
gem 'ransack'
gem 'will_paginate'
gem "chartkick"
gem 'groupdate'
gem 'local_time'
gem "recaptcha"
gem 'rack-cors'
gem 'friendly_id'
gem 'whenever', require: false
gem 'httparty'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.7.3', require: false
gem 'mailgun-ruby'
gem 'sinatra', require: false
gem 'jsonapi-serializer'

gem 'net-ssh', '>= 6.0.2'
gem 'ed25519', '>= 1.2', '< 2.0'
gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0'

# Display performance information such as SQL time and flame graphs for each request in your browser.
# Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
gem 'rack-mini-profiler', '~> 3.0', require: false
gem 'flamegraph'
gem 'stackprof'
gem 'memory_profiler'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'pry'
  gem 'faker'
end

group :development do
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  
  # deployment gems
  gem "capistrano"
  gem "capistrano-rails"
  gem 'capistrano3-puma'
  gem 'capistrano-rbenv'
  gem 'capistrano-local-precompile'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
  gem 'simplecov', require: false, group: :test
  gem 'rails-controller-testing'
  gem 'mocha'
  gem 'webmock'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "graphql", "~> 2.0"
gem 'graphiql-rails'
gem "ember-cli-rails", "0.10.0"
# Access an interactive console on exception pages or by calling 'console' anywhere in the code.
gem 'web-console', '>= 4.1.0'
gem "exception_notification", "~> 4.5"


gem "turnout", "~> 2.5"

if next?
  gem "turbo-rails", "~> 2.0"
else
  gem "turbo-rails", "~> 1.1"
end

gem "redis-namespace", "~> 1.8"

gem 'stripe-rails'

gem 'devise-two-factor', "4.0.2"

gem "slowpoke"

gem "strong_migrations"
gem "simple_calendar", "~> 3.0"

gem "icalendar", "~> 2.9"

gem "blazer", "~> 2.6"

gem "rqrcode", "~> 2.2"

gem "puppeteer-ruby", "~> 0.45.6"

