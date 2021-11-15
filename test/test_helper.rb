ENV['RAILS_ENV'] ||= 'test'
require 'simplecov'
SimpleCov.start 'rails' do
  # filtering out models because it doesnt track coverage on models for some reason (i suspect the apartment gem is to blame)
  add_filter "app/models/"
  # these arent customized. so these dont need to be integration tested
  add_filter "app/controllers/users/confirmations_controller.rb"
  add_filter "app/controllers/users/omniauth_callbacks_controller.rb"
  add_filter "app/controllers/users/passwords_controller.rb"
  add_filter "app/controllers/users/unlocks_controller.rb"
  add_filter "app/mailers/devise_mailer.rb"
  add_filter "app/channels/application_cable/channel.rb"
  add_filter "app/channels/application_cable/connection.rb"
  add_filter "app/jobs/application_job.rb"
end
require_relative "../config/environment"
require "rails/test_help"
require 'mocha/minitest'
require 'webmock/minitest'

class ActiveSupport::TestCase
  include ActiveJob::TestHelper
  # Run tests in parallel with specified workers
  if ENV['PARALLEL_MINITEST']
    parallelize(workers: :number_of_processors)
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
