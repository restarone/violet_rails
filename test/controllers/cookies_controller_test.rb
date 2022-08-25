require "test_helper"

class CookiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Subdomain.current.update(cookies_consent_ui: 'We use cookies', tracking_enabled: true)
  end

  test "should get index" do
    get cookies_url
    assert_response :success
  end

  test "should only show cookies consent UI if cookies_accpected cookie is nil" do
    get cookies_url
    assert_includes response.parsed_body, 'We use cookies'
  end

  test "should set cookies_accepted cookies and should not show cookies consent UI if cookies_accpected cookie is not nil" do
    get cookies_url, params: { cookies: true}
    assert_equal 'true', response.cookies['cookies_accepted']
    refute_includes response.parsed_body, 'We use cookies'

    get cookies_url, params: { cookies: false}
    assert_equal 'false', response.cookies['cookies_accepted']
    refute_includes response.parsed_body, 'We use cookies'
  end
end
