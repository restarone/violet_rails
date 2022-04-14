require "test_helper"

class Comfy::Cms::ContentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
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

  test "get root page (tracking enabled)" do
    @restarone_subdomain.update!(tracking_enabled: true)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_difference "Ahoy::Event.count", +1 do
          perform_enqueued_jobs do
            get root_url(subdomain: @restarone_subdomain.name)
          end
      end
    end
  end

  test "get root page (tracking disabled)" do
    @restarone_subdomain.update!(tracking_enabled: false)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_no_difference "Ahoy::Event.count" do
          perform_enqueued_jobs do
            get root_url(subdomain: @restarone_subdomain.name)
          end
      end
    end
  end

  test "deny restricted page (redirect to login)" do
    get root_url(subdomain: @restarone_subdomain.name)
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "deny restricted page (redirect to admin)" do
    refute @user.can_view_restricted_pages
    sign_in(@user)
    get root_url(subdomain: @restarone_subdomain.name)
    assert_response :redirect
    assert_redirected_to comfy_admin_cms_path
  end

  test "allow restricted page (if permissioned)" do
    @user.update(can_view_restricted_pages: true)
    assert @user.can_view_restricted_pages
    sign_in(@user)
    get root_url(subdomain: @restarone_subdomain.name)
    assert_response :success
  end
end
