require 'simplecov'
SimpleCov.start 'rails'
ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)
  setup do
    Subdomain.create!(name: 'restarone')
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
