require "test_helper"

class Comfy::Admin::Blog::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      @site = Comfy::Cms::Site.first
      @user = User.first
      @user.update(can_manage_web: true)
      
      @layout = @site.layouts.last
      @page = @layout.pages.last
    end
  end

  test 'denies #index if not permissioned' do
    sign_in(@user)
    get comfy_admin_blog_posts_url(subdomain: @restarone_subdomain, site_id: @site.id)
    assert_response :redirect
  end

  test 'denies #new if not permissioned' do
    sign_in(@user)
    get new_comfy_admin_blog_post_url(subdomain: @restarone_subdomain, site_id: @site.id)
    assert_response :redirect
  end

  test 'denies #edit if not permissioned' do
    sign_in(@user)
    get edit_comfy_admin_blog_post_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end

  test 'denies #update if not permissioned' do
    sign_in(@user)
    patch comfy_admin_blog_post_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end


  test 'denies #destroy if not permissioned' do
    sign_in(@user)
    delete comfy_admin_blog_post_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end
end
