require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @public_subdomain = @user.subdomain
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
  end

  test 'renders login page for global admins (public schema)' do
    get new_global_admin_session_url
    assert_response :success
    assert_template :new
  end

  test 'renders login page for tenant users (tenant schema)' do
    get new_user_session_url(subdomain: @restarone_subdomain)
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
    post user_session_url(subdomain: @restarone_subdomain), params: payload
    assert_response :redirect
    refute flash.alert
    assert_equal flash.notice, 'Signed in successfully.'
    assert_redirected_to root_url(subdomain: @restarone_subdomain)
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
end
