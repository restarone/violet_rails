require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:public)
    @public_subdomain = @customer.subdomains.first
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    @restarone_customer = @restarone_subdomain.customer
    @user = users(:public)
  end

  test "should allow create" do
    subdomain = 'tester'
    email = 'test@tester.com'
    password = '123456'
    payload = {
      user: {
        subdomain: subdomain,
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    Apartment::Tenant.switch(@public_subdomain.name) do
      assert_difference "User.all.reload.size", +1 do
        post user_registration_url(subdomain: @public_subdomain.name), params: payload
        assert_response :redirect
        assert_redirected_to root_url(subdomain: @public_subdomain.name)
      end
    end

    Apartment::Tenant.switch(@restarone_subdomain.name) do
      assert_difference "User.all.reload.size", +1 do
        post user_registration_url(subdomain: @restarone_subdomain.name), params: payload
        assert_response :redirect
        assert_redirected_to root_url(subdomain: @restarone_subdomain.name)
      end
    end
  end

  test 'unconfirmed login results in redirect to subdomain landing page' do
    subdomain = 'tester'
    email = 'test@tester.com'
    password = '123456'
    payload = {
      user: {
        subdomain: subdomain,
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    Apartment::Tenant.switch(@public_subdomain.name) do
      assert_difference "User.all.reload.size", +1 do
        post user_registration_url(subdomain: @public_subdomain.name), params: payload
        assert_response :redirect
        assert_redirected_to root_url(subdomain: @public_subdomain.name)
      end
    end
    get new_user_session_url(subdomain: @public_subdomain.name)
    assert_response :success
    assert_template :new
    post user_session_url(subdomain: @public_subdomain.name), params: {user: {email: email, password: password}}
    assert_response :redirect
    assert_equal flash.alert, "You have to confirm your email address before continuing."
  end

  test 'confirmed login results in redirect to comfy admin panel' do
    get comfy_admin_cms_url(subdomain: @public_subdomain.name)
    assert_response :redirect
    email = 'hello-world@restarone.solutions'
    password = '123456'
    payload = {
      user: {
        email: email,
        password: password,
      }
    }
    post user_session_url(subdomain: @public_subdomain.name), params: payload
    assert_response :redirect
    assert_redirected_to comfy_admin_cms_url(subdomain: @public_subdomain.name)
  end

  test 'login to comfy admin panel' do
    sign_in(@user)
    Apartment::Tenant.switch @public_subdomain.name do
      get comfy_admin_cms_url(subdomain: @public_subdomain.name)
      assert_redirected_to comfy_admin_cms_site_pages_path(subdomain: @restarone_subdomain, site_id: Comfy::Cms::Site.first.id)
    end
  end
end
