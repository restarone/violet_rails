require "test_helper"

class Comfy::Admin::Cms::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:public)
    @customer_subdomain = @customer.subdomains.first.name
    @restarone_customer = Subdomain.find_by(name: 'restarone').customer
    @restarone_subdomain = @restarone_customer.subdomains.first.name
    sign_in(@restarone_customer)
  end

  test "get comfy root" do
    get comfy_admin_cms_url(subdomain: @restarone_subdomain)
    assert_redirected_to comfy_admin_cms_site_pages_path(subdomain: @restarone_subdomain, site_id: 1)
  end

  test "should not get admin index if not logged in" do
    sign_out(@restarone_customer)
    get comfy_admin_cms_site_layouts_url(subdomain: @customer_subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to new_customer_session_path(subdomain: @customer_subdomain)
  end

  test "should not get admin index if not logged in (redirects to public site)" do
    sign_out(@restarone_customer)
    get comfy_admin_cms_site_layouts_url(subdomain: @customer_subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to new_customer_session_path(subdomain: @restarone_subdomain)
  end

  test "should get admin index" do
    get comfy_admin_cms_site_layouts_url(subdomain: @restarone_subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :success
  end

  test "should not get admin index if not confirmed" do
    sign_out(@restarone_customer)
    @customer.update(confirmed_at: nil)
    sign_in(@customer)
    get comfy_admin_cms_site_layouts_url(subdomain: @customer_subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to new_customer_session_path(subdomain: @customer_subdomain)
  end
end
