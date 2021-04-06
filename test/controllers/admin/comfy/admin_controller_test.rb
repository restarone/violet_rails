require "test_helper"

class Comfy::Admin::Cms::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:public)
    @restarone_customer = Customer.find_by(subdomain: 'restarone')
    sign_in(@restarone_customer)
  end

  test "should not get admin index if not logged in" do
    sign_out(@restarone_customer)
    get comfy_admin_cms_site_layouts_url(subdomain: @customer.subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to new_customer_session_path(subdomain: @customer.subdomain)
  end

  test "should not get admin index if not logged in (redirects to public site)" do
    get comfy_admin_cms_site_layouts_url(subdomain: @customer.subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to root_path(subdomain: @customer.subdomain)
  end

  test "should get admin index" do
    get comfy_admin_cms_site_layouts_url(subdomain: @restarone_customer.subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :success
  end

  test "should not get admin index if not confirmed" do
    sign_out(@restarone_customer)
    sign_in(@customer)
    get comfy_admin_cms_site_layouts_url(subdomain: @customer.subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to new_customer_session_path(subdomain: @customer.subdomain)
  end

  test "should get admin index once confirmed" do
    skip('need to look further into this')
    sign_out(@restarone_customer)
    sign_in(@customer)
    get comfy_admin_cms_site_layouts_url(subdomain: @customer.subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to new_customer_session_path(subdomain: @customer.subdomain)
    @customer.update(confirmed_at: Time.now)
    get comfy_admin_cms_site_layouts_url(subdomain: @customer.subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :success
  end
end
