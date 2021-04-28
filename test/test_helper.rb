ENV['RAILS_ENV'] ||= 'test'
require 'simplecov'
SimpleCov.start 'rails' do
  # filtering out models because it doesnt track coverage on models for some reason (i suspect the apartment gem is to blame)
  add_filter "app/models/"
end
require_relative "../config/environment"
require "rails/test_help"
require 'mocha/minitest'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  if ENV['PARALLEL_MINITEST']
    parallelize(workers: :number_of_processors)
  end
  setup do
    subdomain = Subdomain.create!(name: 'restarone')
    Apartment::Tenant.switch subdomain.name do
      User.create!(email: 'contact@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)
    end
  end

  teardown do
    Apartment::Tenant.drop('public') rescue nil
    Apartment::Tenant.drop('restarone') rescue nil
  end
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # custom config for mocking out actionmailer mailgun config without actually setting it as the delivary method
  Rails.application.config.action_mailer.mailgun_settings = {
    api_key: 'hardcodedapikey',
    domain: 'mg.restarone.solutions',
  }

  class ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ActiveJob::TestHelper
  end
  

  class ActionMailbox::TestCase
    include ActiveJob::TestHelper
  end
end
