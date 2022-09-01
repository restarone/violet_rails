require "test_helper"

class Comfy::Blog::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @site = Comfy::Cms::Site.first

      @layout = @site.layouts.last
      @page = @layout.pages.last

      @blog_post = @site.blog_posts.create!(
        layout: @layout, 
        title: 'foo',
        slug: 'foo'
      )
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

  test 'tracks blog post visit (if enabled and cookies accepted)' do
    @restarone_subdomain.update(tracking_enabled: true)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_difference "Ahoy::Event.count", +1 do
        get comfy_blog_post_url(subdomain: @restarone_subdomain.name, year: @blog_post.year, month: @blog_post.month, slug: @blog_post.slug), headers: {"HTTP_COOKIE" => "cookies_accepted=true;"}
      end
    end
    assert_response :success
  end

  test 'does not track blog post visit (if disabled)' do
    @restarone_subdomain.update(tracking_enabled: false)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_no_difference "Ahoy::Event.count" do
        get comfy_blog_post_url(subdomain: @restarone_subdomain.name, year: @blog_post.year, month: @blog_post.month, slug: @blog_post.slug)
      end
    end
    assert_response :success
  end

  test 'does not track blog post visit (if enabled and cookies not consented)' do
    @restarone_subdomain.update(tracking_enabled: true)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_no_difference "Ahoy::Event.count" do
        get comfy_blog_post_url(subdomain: @restarone_subdomain.name, year: @blog_post.year, month: @blog_post.month, slug: @blog_post.slug)
      end
    end
    assert_response :success
  end

  test 'does not track blog post visit (if enabled and cookies disabled)' do
    @restarone_subdomain.update(tracking_enabled: true)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_no_difference "Ahoy::Event.count" do
        get comfy_blog_post_url(subdomain: @restarone_subdomain.name, year: @blog_post.year, month: @blog_post.month, slug: @blog_post.slug), headers: {"HTTP_COOKIE" => "cookies_accepted=false;"}
      end
    end
    assert_response :success
  end

  test 'does not track blog post visit (if disabled and cookies enabled)' do
    @restarone_subdomain.update(tracking_enabled: false)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_no_difference "Ahoy::Event.count" do
        get comfy_blog_post_url(subdomain: @restarone_subdomain.name, year: @blog_post.year, month: @blog_post.month, slug: @blog_post.slug), headers: {"HTTP_COOKIE" => "cookies_accepted=true;"}
      end
    end
    assert_response :success
  end
end
