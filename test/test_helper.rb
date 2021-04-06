ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  setup do
    Customer.create!(subdomain: 'restarone', email: 'contact@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)
  end

  class ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
  # Add more helper methods to be used by all tests here...
end
