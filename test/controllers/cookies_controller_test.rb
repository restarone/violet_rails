require "test_helper"

class CookiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Subdomain.current.update(cookies_consent_ui: 'We use cookies', tracking_enabled: true)
  end

  test "should get index" do
    get cookies_url
    assert_response :redirect
  end

  test "should set cookies_accepted cookies and should not show cookies consent UI if cookies_accpected cookie is not nil for html request" do
    get cookies_url(format: :html), params: { cookies: true}
    assert_equal 'true', response.cookies['cookies_accepted']

    get cookies_url(format: :html), params: { cookies: false}
    assert_equal 'false', response.cookies['cookies_accepted']
  end

  test "should set/reset cookies_accepted cookies accordingly for turbo request" do
    get cookies_url(format: :turbo), params: { cookies: true}
    assert_equal 'true', response.cookies['cookies_accepted']

    get cookies_url(format: :turbo), params: { cookies: false}
    assert_equal 'false', response.cookies['cookies_accepted']
  end

  test "should set/reset cookies_accepted cookies accordingly for json request" do
    get cookies_url(format: :json), params: { cookies: true}
    assert_equal 'true', response.cookies['cookies_accepted']

    get cookies_url(format: :json), params: { cookies: false}
    assert_equal 'false', response.cookies['cookies_accepted']
  end

  test "should set/reset cookies_accepted cookies accordingly for ajax request" do
    get cookies_url, params: { cookies: true}, xhr: true
    assert_equal 'true', response.cookies['cookies_accepted']

    get cookies_url, params: { cookies: false}, xhr: true
    assert_equal 'false', response.cookies['cookies_accepted']
  end
end
