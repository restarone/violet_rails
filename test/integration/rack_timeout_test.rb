# require "test_helper"

# class RackTimeoutTest < ActionDispatch::IntegrationTest
#   setup do
#     setup_fake_routes
#   end

#   teardown do
#     Rails.application.reload_routes!
#   end

#   def setup_fake_routes
#     Rails.application.routes.draw do
#       get '/sleep', to: -> (env) { 
#         sleep(0.5) 
#         [200, {}, ['Hello, world!']]
#       }
#       get '/root', to: -> (env) { 
#         [200, {}, ['Hello from root page!']]
#       }
#     end
#   end

#   class MyModel
#     def foo
#       "bar"
#     end
#   end

#   class MyBackgroundJob < ApplicationJob
#     def perform
#       sleep(2)
#       MyModel.new.foo
#     end
#   end

#   test "should interrupt request when timeout is exceeded" do
#     Rack::Timeout.any_instance.stubs(:service_timeout).returns(0.1)
#     assert_raises(Rack::Timeout::RequestTimeoutError) do
#       get "/sleep"
#     end
#   end

#   test "should not interrupt request when timeout is not exceeded" do
#     Rack::Timeout.any_instance.stubs(:service_timeout).returns(1)
#     get "/sleep"
#     assert_response :success
#   end

#   test "should interrupt request and check server health" do
#     Rack::Timeout.any_instance.stubs(:service_timeout).returns(0.1)
#     assert_raises(Rack::Timeout::RequestTimeoutError) do
#       get "/sleep"
#     end

#     # Assert that a request to a healthy endpoint succeeds
#     get '/root'
#     assert_response :success
#   end

#   test "should run other requests and background job should run even after request timeout exception" do
#     Rack::Timeout.any_instance.stubs(:service_timeout).returns(0.1)
#     MyBackgroundJob.perform_now
#     assert_raises(Rack::Timeout::RequestTimeoutError) do
#       get "/sleep"
#     end

#     # Assert that a request to a healthy endpoint succeeds
#     get '/root'
#     assert_response :success

#     # Assert that the background job succeeds after request exception
#     assert_equal "bar", MyBackgroundJob.new.perform
#   end

# end