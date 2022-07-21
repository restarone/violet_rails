require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @public_subdomain = @user.subdomain
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
  end

  test 'renders login page for global admins (public schema)' do
    get new_global_admin_session_url
    assert_response :success
    assert_template :new
  end

  test 'renders login page for tenant users (tenant schema)' do
    get new_user_session_url(subdomain: @restarone_subdomain.name)
    assert_response :success
    assert_template :new
  end

  test 'redirects to subdomain after tenant user logs in (tenant schema)' do
    payload = {
      user: {
        email: @restarone_user.email,
        password: '123456'
      }
    }
    post user_session_url(subdomain: @restarone_subdomain.name), params: payload
    assert_response :redirect
    refute flash.alert
    assert_equal flash.notice, 'Signed in successfully.'
    assert_redirected_to root_url(subdomain: @restarone_subdomain.name)
  end

  test 'redirects to subdomain admin if the user is allowed to access admin area + can manage web' do
    payload = {
      user: {
        email: @user.email,
        password: '123456'
      }
    }
    @user.update!(can_access_admin: true, can_manage_web: true)
    post user_session_path, params: payload
    follow_redirect!
    assert_redirected_to comfy_admin_cms_site_pages_path(site_id: Comfy::Cms::Site.first.id)
  end

  test 'redirects to subdomain sysadmin if the user is global admin' do
    payload = {
      user: {
        email: @user.email,
        password: '123456'
      }
    }
    @user.update!(global_admin: true)
    post user_session_path, params: payload
    assert_redirected_to admin_subdomain_requests_path
  end

  test 'redirects to page if defined' do
    @user.update!(can_access_admin: false)
    layout = Comfy::Cms::Site.first.layouts.create(
      label: 'default',
      identifier: 'default',
      content: "{{cms:wysiwyg content}}",
      app_layout: 'website'
    )
    page = layout.pages.create(
      site_id: Comfy::Cms::Site.first.id,
      label: 'foo',
      slug: 'foo'
    )
    subdomains(:public).update!(after_sign_in_path: '/foo')
    payload = {
      user: {
        email: @user.email,
        password: '123456'
      }
    }
    post user_session_path, params: payload
    assert_redirected_to '/foo'
  end

  test 'tenant user is not found in global admin (public schema)' do
    payload = {
      user: {
        email: @restarone_user.email,
        password: '123456'
      }
    }
    post users_sign_in_url, params: payload
    assert_response :success
    assert_template :new
    assert_equal flash.alert, "Invalid Email or password."
  end

  test '#create allows login for global admin' do
    @user.update(global_admin: true)
    payload = {
      user: {
        email: @user.email,
        password: '123456'
      }
    }
    post users_sign_in_url, params: payload
    assert_redirected_to admin_subdomain_requests_url
    follow_redirect!
    assert_template :index
  end

  test '#create denies login with' do
    payload = {
      user: {
        email: @user.email,
        password: ''
      }
    }
    post users_sign_in_url, params: payload
    
    assert_template :new
    assert_match "Invalid Email or password.", flash[:alert]
  end

  test 'redirects to private cms-page after sign-in successfully' do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update!(can_access_admin: false)
      site = Comfy::Cms::Site.first
      layout = site.layouts.last
      page = layout.pages.create(
        site_id: site.id,
        label: 'test-cms-page',
        slug: 'test-cms-page',
        is_restricted: true
      )
  
      # First, trying to visit a private cms page which redirects to sign_in page
      get comfy_cms_render_page_url(subdomain: @restarone_subdomain.name, cms_path: 'test-cms-page')
      assert_redirected_to new_user_session_url(subdomain: @restarone_subdomain.name)
  
      payload = {
        user: {
          email: @restarone_user.email,
          password: '123456'
        }
      }

      # After signing-in, it should redirect back to the private cms page
      post user_session_url(subdomain: @restarone_subdomain.name), params: payload
      assert_redirected_to page.full_path
    end
  end

  test 'redirects to private forum-thread page after sign-in successfully' do
    @restarone_subdomain.update!(forum_is_private: true)

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update!(can_access_admin: true)

      forum_category = ForumCategory.create!(name: 'test', slug: 'test')
      forum_thread = @restarone_user.forum_threads.create!(title: 'Test Thread 1', forum_category_id: forum_category.id)
  
      # First, trying to visit a private forum-thread page which redirects to sign_in page
      get simple_discussion.forum_thread_url(subdomain: @restarone_subdomain.name, id: forum_thread.id)
      assert_redirected_to new_user_session_url(subdomain: @restarone_subdomain.name)
  
      payload = {
        user: {
          email: @restarone_user.email,
          password: '123456'
        }
      }

      # After signing-in, it should redirect back to the private forum-thread page
      post user_session_url(subdomain: @restarone_subdomain.name), params: payload
      assert_redirected_to simple_discussion.forum_thread_url(subdomain: @restarone_subdomain.name, id: forum_thread.id)
    end
  end
end
