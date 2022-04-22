require "test_helper"

class Comfy::Cms::ContentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      @site = Comfy::Cms::Site.first
      @user = User.first
      refute @user.can_manage_web
      @layout = @site.layouts.last
      @page = @layout.pages.first
      @page.update(is_restricted: true)
    end
  end

  test "get root page" do
    get root_url
    assert_response :success
  end

  test "deny restricted page (redirect to login)" do
    get root_url(subdomain: @restarone_subdomain)
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "deny restricted page (redirect to admin)" do
    refute @user.can_view_restricted_pages
    sign_in(@user)
    get root_url(subdomain: @restarone_subdomain)
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "allow restricted page (if permissioned)" do
    @user.update(can_view_restricted_pages: true)
    assert @user.can_view_restricted_pages
    sign_in(@user)
    get root_url(subdomain: @restarone_subdomain)
    assert_response :success
  end
end
