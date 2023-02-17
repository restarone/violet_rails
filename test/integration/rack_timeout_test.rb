require "test_helper"

class RackTimeoutTest < ActionDispatch::IntegrationTest
  setup do
    # create fake routes to mock long processing time
    Rails.application.routes.draw do
      get '/sleep', to: -> (env) { 
        sleep(0.5) 
        [200, {}, ['Hello, world!']]
      }
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "should interrupt request when timeout is exceeded" do
    Rack::Timeout.any_instance.stubs(:service_timeout).returns(0.1)
    assert_raises(Rack::Timeout::RequestTimeoutError) do
      get "/sleep"
    end
  end

  test "should not interrupt request when timeout is not exceeded" do
    Rack::Timeout.any_instance.stubs(:service_timeout).returns(1)
    get "/sleep"
    assert_response :success
  end
end