require "test_helper"

class Comfy::Blog::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @site = Comfy::Cms::Site.first

      @layout = @site.layouts.last
      @page = @layout.pages.last
    end
  end

  test 'denies index if blog is disabled' do
    @restarone_subdomain.update(blog_enabled: false)
    get comfy_blog_posts_url(subdomain: @restarone_subdomain.name)
    assert_response :redirect
  end

  test 'allows index if blog is enabled' do
    assert @restarone_subdomain.blog_enabled
    get comfy_blog_posts_url(subdomain: @restarone_subdomain.name)
    assert_response :success
    assert_template :index
  end
end
