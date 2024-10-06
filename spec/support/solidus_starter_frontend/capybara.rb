# frozen_string_literal: true

require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'capybara/apparition'
require 'spree/testing_support/capybara_ext'

# Allow to override the initial windows size
CAPYBARA_WINDOW_SIZE = ENV.fetch('CAPYBARA_WINDOW_SIZE', '1920x1080').split('x', 2).map(&:to_i)
CAPYBARA_WINDOW_WIDTH = CAPYBARA_WINDOW_SIZE[0]
CAPYBARA_WINDOW_HEIGHT = CAPYBARA_WINDOW_SIZE[1]

Capybara.javascript_driver = ENV.fetch('CAPYBARA_JAVASCRIPT_DRIVER', "solidus_chrome_headless").to_sym
Capybara.default_max_wait_time = 10
Capybara.server = :puma, { Silent: true } # A fix for rspec/rspec-rails#1897

Capybara.register_driver :apparition do |app|
  Capybara::Apparition::Driver.new(app, window_size: CAPYBARA_WINDOW_SIZE)
end

Capybara.register_driver :apparition_docker_friendly do |app|
  opts = {
    headless: true,
    browser_options: [
      :no_sandbox,
      :disable_gpu,
      { disable_features: 'VizDisplayCompositor' }
    ]
  }
  Capybara::Apparition::Driver.new(app, opts)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by((ENV['CAPYBARA_DRIVER'] || :rack_test).to_sym)
  end

  config.before(:each, type: :system, js: true) do
    driven_by((ENV['CAPYBARA_JS_DRIVER'] || :apparition).to_sym)
  end
end
