require "test_helper"

class Comfy::Admin::Cms::SitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      @site = Comfy::Cms::Site.first
      @user = User.first
      refute @user.can_manage_web
      @layout = @site.layouts.last
      @page = @layout.pages.last
    end
  end
  test 'denies all actions' do
    get comfy_admin_cms_sites_url(subdomain: @restarone_subdomain)
    assert_response :redirect
    post comfy_admin_cms_sites_url(subdomain: @restarone_subdomain)
    assert_response :redirect
    get new_comfy_admin_cms_site_url(subdomain: @restarone_subdomain)
    assert_response :redirect
    get edit_comfy_admin_cms_site_url(subdomain: @restarone_subdomain, id: @site.id)
    assert_response :redirect
    patch comfy_admin_cms_site_url(subdomain: @restarone_subdomain, id: @site.id)
    assert_response :redirect
    delete comfy_admin_cms_site_url(subdomain: @restarone_subdomain, id: @site.id)
    assert_response :redirect
  end

end
