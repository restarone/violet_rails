ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"
require 'mocha/minitest'
require 'webmock/minitest'
require 'sidekiq/testing'

class ActiveSupport::TestCase
  include ActiveJob::TestHelper
  # Run tests in parallel with specified workers
  if ENV['PARALLEL_MINITEST']
    parallelize(workers: :number_of_processors)
  else
    parallelize(workers: 1)
  end
  setup do
    subdomain = Subdomain.create!(name: 'restarone')
    Apartment::Tenant.switch subdomain.name do
      User.create!(email: 'contact@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)
    end
    stub_request(:post, "www.example.com/success").to_return(body: "success response", status: 200)
    stub_request(:post, "www.example.com/error").to_return(body: "error response", status: 500)
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
    Ahoy.track_bots = true
  end
  

  class ActionMailbox::TestCase
    include ActiveJob::TestHelper
  end
end
