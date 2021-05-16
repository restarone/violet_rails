require "test_helper"

class Subdomains::Admin::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
  end

  test "should now allow passthrough if not authenticated" do
    get admin_subdomain_requests_url
    assert_redirected_to new_global_admin_session_path
  end

  test "should now allow passthrough if not super admin" do
    refute @user.global_admin
    sign_in(@user)
    get admin_subdomain_requests_url
    assert_redirected_to root_path
  end

  test "should now allow passthrough if super admin" do
    @user.update(global_admin: true)
    assert @user.global_admin
    sign_in(@user)
    get admin_subdomain_requests_url
    assert_response :success
    assert_template :index
  end
end
