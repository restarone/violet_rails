require "test_helper"

class Comfy::Admin::Cms::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user_subdomain = @user.subdomain
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @unauthorized_user = User.create!(email: 'design@restarone.com', password: '123456', password_confirmation: '123456')
      @unauthorized_user.update(confirmed_at: Time.now)
    end
    sign_in(@user)
  end

  test "get comfy root" do
    get comfy_admin_cms_url(subdomain: @user_subdomain)
    assert_redirected_to comfy_admin_cms_site_pages_path(subdomain: @user_subdomain, site_id: Comfy::Cms::Site.first.id)
  end

  test "should not get admin index if not logged in" do
    sign_out(@user)
    get comfy_admin_cms_site_layouts_url(subdomain: @user_subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to new_user_session_path(subdomain: @user_subdomain)
  end

  test "should not get admin index if attempting to access different subdomain than what they are associated with" do
    get comfy_admin_cms_site_layouts_url(subdomain: @restarone_subdomain.name, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to root_url
  end


  test "should redirect to layouts#new while accessing layouts#index if there are no layouts" do
    Comfy::Cms::Layout.delete_all
    get comfy_admin_cms_site_layouts_url(subdomain: @user_subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to new_comfy_admin_cms_site_layout_url(subdomain: @user_subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_redirected_to action: :new
  end

  test "should get admin index" do
    get comfy_admin_cms_site_layouts_url(subdomain: @user_subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_template :index
    assert_response :success
  end


  test "should not get admin index if not confirmed" do
    sign_out(@user)
    @user.update(confirmed_at: nil)
    sign_in(@user)
    get comfy_admin_cms_site_layouts_url(subdomain: @user_subdomain, site_id: Comfy::Cms::Site.first.id)
    assert_response :redirect
    assert_redirected_to new_user_session_path(subdomain: @user_subdomain)
  end
end
