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
    post user_session_url, params: payload
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
    post user_session_url, params: payload
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
    post user_session_url, params: payload
    
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

      # It should redirect back to the root_url if the user cannot view restricted pages
      @restarone_user.update!(can_view_restricted_pages: false)
      sign_in(@restarone_user)
      get comfy_cms_render_page_url(subdomain: @restarone_subdomain.name, cms_path: 'test-cms-page')
      assert_redirected_to root_url(subdomain: @restarone_subdomain.name)

      # It should render private cms-page successfully if the user can view restricted pages
      @restarone_user.update!(can_view_restricted_pages: true)
      sign_in(@restarone_user)
      get comfy_cms_render_page_url(subdomain: @restarone_subdomain.name, cms_path: 'test-cms-page')
      assert_response :success
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

  test 'redirects to api-namespace page after sign-in successfully' do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update!(can_access_admin: true)

      api_namespace = ApiNamespace.create!(name: 'clients',
        slug: 'clients',
        version: 1,
        properties: {'name': 'test'},
        requires_authentication: false,
        namespace_type: 'create-read-update-delete')

      # First, trying to visit api-namespace page which redirects to sign_in page
      get api_namespace_url(subdomain: @restarone_subdomain.name, id: api_namespace.id)
      assert_redirected_to new_user_session_url(subdomain: @restarone_subdomain.name)
  
      payload = {
        user: {
          email: @restarone_user.email,
          password: '123456'
        }
      }

      # After signing-in, it should redirect back to the api-namespace page
      post user_session_url(subdomain: @restarone_subdomain.name), params: payload
      assert_redirected_to api_namespace_url(subdomain: @restarone_subdomain.name, id: api_namespace.id)

      # The response will be success if the user can manage api
      @restarone_user.update!(can_manage_api: true)
      sign_in(@restarone_user)
      get api_namespace_url(subdomain: @restarone_subdomain.name, id: api_namespace.id)
      assert_response :success

      # The response will be redirected to root_url  if the user cannot manage api
      @restarone_user.update!(can_manage_api: false)
      sign_in(@restarone_user)
      get api_namespace_url(subdomain: @restarone_subdomain.name, id: api_namespace.id)
      assert_redirected_to root_url(subdomain: @restarone_subdomain.name)
    end
  end

  test 'should allow #login without otp if enable_2fa is set to false' do
    Subdomain.current.update(enable_2fa: false)
    @user.update(global_admin: true)
    payload = {
      user: {
        email: @user.email,
        password: '123456'
      }
    }
    post user_session_url, params: payload
    assert_redirected_to admin_subdomain_requests_url
  end

test 'should deny #login with wrong otp if enable_2fa is set to true' do
  Subdomain.current.update(enable_2fa: true)
  payload = {
    user: {
      email: @user.email,
      password: '123456',
    }
  }
  post user_session_url, params: payload
  assert_template 'users/sessions/two_factor'
  payload = {
    user: {
      email: @user.email,
      password: '123456',
      otp_attempt: 'sdfsdf'
    }
  }
  post user_session_url, params: payload
  assert_equal flash.alert, "Invalid two-factor code."
end

test "should allow #login without otp if enable_2fa is set to true and current_sign_in_ip is equal to user's current ip" do
  Subdomain.current.update(enable_2fa: true)
  @user.update(global_admin: true, current_sign_in_ip: '172.18.1.0')
  payload = {
    user: {
      email: @user.email,
      password: '123456',
    }
  }
  post user_session_url, params: payload, env: { "REMOTE_ADDR": "172.18.1.0" }
  assert_redirected_to admin_subdomain_requests_url
end

test "should deny #login without otp if enable_2fa is set to true and current_sign_in_ip is not equal to user's current ip" do
  Subdomain.current.update(enable_2fa: true)
  @user.update(current_sign_in_ip: '172.18.1.0')
  payload = {
    user: {
      email: @user.email,
      password: '123456',
    }
  }
  post user_session_url, params: payload, env: { "REMOTE_ADDR": "172.20.1.1" }
  assert_template 'users/sessions/two_factor'

  payload = {
    user: {
      email: @user.email,
      password: '123456',
    }
  }
  post user_session_url, params: payload, env: { "REMOTE_ADDR": "172.20.1.1" }
  assert_equal flash.alert, "OTP Required."
end

test "should allow #login with otp if enable_2fa is set to true and current_sign_in_ip is not equal to user's current ip" do
  Subdomain.current.update(enable_2fa: true)
  # successful login and displaying 2fa page
  @user.update(global_admin: true, current_sign_in_ip: '172.18.1.0')
  payload = {
    user: {
      email: @user.email,
      password: '123456',
    },
  }
  post user_session_url, params: payload, env: { "REMOTE_ADDR": "172.18.1.1" }
  assert_template 'users/sessions/two_factor'

  # valid otp and redirection to admin subdomain page
  payload = {
    user: {
      email: @user.email,
      password: '123456',
      otp_attempt: @user.reload.current_otp,
    },
    session: { otp_user_id: @user.id } 
  }
  post user_session_url, params: payload, env: { "REMOTE_ADDR": "172.18.1.1" }
  assert_redirected_to admin_subdomain_requests_url
  follow_redirect!
  assert_template :index
end

test 'should reset the otp_user_id for session in initial render' do
  get new_user_session_path
  assert_nil session[:otp_user_id]
end
end
