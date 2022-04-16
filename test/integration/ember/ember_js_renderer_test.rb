require "test_helper"

class EmberJsRendererTest < ActionDispatch::IntegrationTest
  test "should render ember app if enabled" do
    subdomains(:public).update!(ember_enabled: true)
    get '/app'
    assert_response :success
    assert_equal path, '/app'
  end

  test "should redirect if not enabled" do
    subdomains(:public).update!(ember_enabled: false)
    get '/app'
    follow_redirect!
    assert_equal path, '/'
  end
end
