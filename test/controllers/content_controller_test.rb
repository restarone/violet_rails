require "test_helper"

class ContentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
    Ahoy::Visit.destroy_all
  end

  test "should get index with ahoy signed cookies only if tracking enabled and cookies accepted" do
    Subdomain.current.update(tracking_enabled: true)
    refute Ahoy::Visit.first
    get root_url, headers: {"HTTP_COOKIE" => "cookies_accepted=true;"}
    assert_response :success
    cookie_keys = ["ahoy_visitor", "ahoy_visit"]
    signed_cookies = cookies.to_hash
    cookie_keys.each do |k|
      assert_includes signed_cookies.keys, k
      assert signed_cookies[k]
    end
    visit = Ahoy::Visit.first
    assert visit
  end

  test "should get index with out ahoy signed cookies only if tracking enabled but cookies rejected" do
    Subdomain.current.update(tracking_enabled: true)
    refute Ahoy::Visit.first
    get root_url, headers: {"HTTP_COOKIE" => "cookies_accepted=false;"}
    assert_response :success
    cookie_keys = ["ahoy_visitor", "ahoy_visit"]
    signed_cookies = cookies.to_hash
    cookie_keys.each do |k|
      refute_includes signed_cookies.keys, k
      refute signed_cookies[k]
    end
    visit = Ahoy::Visit.first
    refute visit
  end

  test "should get index with out ahoy signed cookies only if tracking enabled but cookies not consented" do
    Subdomain.current.update(tracking_enabled: true)
    refute Ahoy::Visit.first
    get root_url
    assert_response :success
    cookie_keys = ["ahoy_visitor", "ahoy_visit"]
    signed_cookies = cookies.to_hash
    cookie_keys.each do |k|
      refute_includes signed_cookies.keys, k
      refute signed_cookies[k]
    end
    visit = Ahoy::Visit.first
    refute visit
  end

  test "should get index with out ahoy signed cookies only if tracking disabled but cookies accepted" do
    Subdomain.current.update(tracking_enabled: false)
    refute Ahoy::Visit.first
    get root_url, headers: {"HTTP_COOKIE" => "cookies_accepted=true;"}
    assert_response :success
    cookie_keys = ["ahoy_visitor", "ahoy_visit"]
    signed_cookies = cookies.to_hash
    cookie_keys.each do |k|
      refute_includes signed_cookies.keys, k
      refute signed_cookies[k]
    end
    visit = Ahoy::Visit.first
    refute visit
  end

  test "should get index" do
    get root_url
    assert_response :success
    get root_url(subdomain: @restarone_user.subdomain)
    assert_response :success
  end

  test "should get index (www redirect)" do
    get root_url(subdomain: 'www')
    assert_response :success
    get root_url(subdomain: @user.subdomain)
    assert_response :success
  end
end
