require "test_helper"

class EmberJsRendererTest < ActionDispatch::IntegrationTest
  test "should render ember app if enabled" do
    skip('ember is broken in ruby 3 due to an issue in ember-cli-rails and is soft deprecated and scheduled for removal in Violet Rails 1.0 (see: https://github.com/restarone/violet_rails/pull/371)')
    subdomains(:public).update!(ember_enabled: true)
    get '/app'
    assert_response :success
    assert_equal path, '/app'
  end

  test "should redirect if not enabled" do
    skip('ember is broken in ruby 3 due to an issue in ember-cli-rails and is soft deprecated and scheduled for removal in Violet Rails 1.0 (see: https://github.com/restarone/violet_rails/pull/371)')
    subdomains(:public).update!(ember_enabled: false)
    get '/app'
    follow_redirect!
    assert_equal path, '/'
  end
end
