# frozen_string_literal: true

source "http://rubygems.org"

gemspec

# Uncomment and change rails version for testing purposes
# gem "rails", "~> 5.0.0"
# gem "rails", "~> 5.1.0"
# gem "rails", "~> 5.2.0"
gem "rails", "~> 6.0.0"

# Rails 5.0 needs lower version of this gem:
# gem "sqlite3", "~> 1.3.0"
gem "sqlite3"

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "rubocop", "0.78.0", require: false
  gem "sassc-rails"
  gem "web-console", ">= 3.3.0"
  gem "webpacker"
end

group :test do
  gem "coveralls", require: false
  gem "diffy"
  gem "equivalent-xml"
  gem "minitest"
  gem "timecop"
end
