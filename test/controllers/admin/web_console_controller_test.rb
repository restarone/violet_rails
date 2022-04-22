require "test_helper"

class Admin::WebConsoleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subdomain = subdomains(:public)
    @user = users(:public)
    @user.update(global_admin: true)
  end


  test 'allows #index if global admin from public schema' do
    @subdomain.update(web_console_enabled: true)
    assert @user.global_admin
    sign_in(@user)
    get admin_web_console_path
    assert_response :success
    assert_template :index
    assert_template layout: "admin"
  end

  test 'denies #index if not global admin from public schema' do
    @user.update(global_admin: false)
    sign_in(@user)
    begin
      get admin_web_console_path
    rescue ActionController::RoutingError => e
      assert_equal "Page Not Found at: \"admin/web_console\"", e.message
    end
  end

  test 'denies #index if web console not enabled' do
    @subdomain.update(web_console_enabled: false)
    assert @user.global_admin
    sign_in(@user)
    get admin_web_console_path
    assert_response :redirect
  end
end
