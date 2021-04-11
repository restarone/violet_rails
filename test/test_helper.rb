require 'simplecov'
SimpleCov.start 'rails'
ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"

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



  class ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
  # Add more helper methods to be used by all tests here...
end
