require "test_helper"

class Comfy::Admin::Cms::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:public)
    #sign_in(@customer)
  end

  test "should get admin index" do
    get comfy_admin_cms_site_layouts_url(subdomain: @customer.subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to new_customer_session_path(subdomain: @customer.subdomain)
  end
end
