require "test_helper"

class Comfy::Admin::Cms::SnippetsControllerTest < ActionDispatch::IntegrationTest
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

  test 'disallows #index if not permissioned' do
    sign_in(@user)
    get comfy_admin_cms_site_snippets_url(subdomain: @restarone_subdomain, site_id: @site.id)
    assert_response :redirect
  end

  test 'denies #new if not permissioned' do
    sign_in(@user)
    get new_comfy_admin_cms_site_snippet_url(subdomain: @restarone_subdomain, site_id: @site.id)
    assert_response :redirect
  end

  test 'denies #edit if not permissioned' do
    sign_in(@user)
    get edit_comfy_admin_cms_site_snippet_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end

  test 'denies #update if not permissioned' do
    sign_in(@user)
    patch comfy_admin_cms_site_snippet_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end


  test 'denies #destroy if not permissioned' do
    sign_in(@user)
    delete comfy_admin_cms_site_snippet_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end
end
