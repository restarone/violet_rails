require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @public_subdomain = @user.subdomain
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
  end

  test "should allow create (within subdomain scope)" do
    email = 'test@tester.com'
    password = '123456'
    payload = {
      user: {
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    Apartment::Tenant.switch(@public_subdomain) do
      assert_difference "User.all.reload.size", +1 do
        post user_registration_url(subdomain: @public_subdomain), params: payload
        assert_response :redirect
      end
    end

    Apartment::Tenant.switch(@restarone_subdomain) do
      assert_difference "User.all.reload.size", +1 do
        post user_registration_url(subdomain: @restarone_subdomain), params: payload
        assert_response :redirect
      end
    end
  end

  test "should allow #new (within subdomain scope)" do
    get new_user_registration_url(subdomain: @public_subdomain)
    assert_response :success
  end

  test 'unconfirmed login results in redirect to subdomain landing page (within subdomain scope)' do
    get new_user_session_url(subdomain: @public_subdomain)
    assert_response :success
    assert_template :new
    @user.update(confirmed_at: nil)
    post user_session_url(subdomain: @public_subdomain), params: {user: {email: @user.email, password: '123456'}}
    assert_response :redirect
    assert_equal flash.alert, "You have to confirm your email address before continuing."
  end

  test 'confirmed login results in redirect to comfy admin panel (within subdomain scope)' do
    get comfy_admin_cms_url(subdomain: @public_subdomain)
    assert_response :redirect
    email = 'hello-world@restarone.solutions'
    password = '123456'
    payload = {
      user: {
        email: email,
        password: password,
      }
    }
    post user_session_url(subdomain: @public_subdomain), params: payload
    assert_response :redirect
    assert_redirected_to comfy_admin_cms_url(subdomain: @public_subdomain)
  end

  test 'login to comfy admin panel (within subdomain scope)' do
    sign_in(@user)
    Apartment::Tenant.switch @public_subdomain do
      get comfy_admin_cms_url(subdomain: @public_subdomain)
      assert_redirected_to comfy_admin_cms_site_pages_path(subdomain: @restarone_subdomain, site_id: Comfy::Cms::Site.first.id)
    end
  end

  test "should allow sign up at subdomain scope" do
    email = 'test1@tester.com'
    password = '123456'
    payload = {
      user: {
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    assert_changes "Devise.mailer.deliveries.size" do          
      assert_changes "User.all.size", +1 do
        post user_registration_url(subdomain: @public_subdomain), params: payload
        assert_response :redirect
        assert_redirected_to root_url(subdomain: @public_subdomain)
        latest_user = User.last
        assert latest_user.email == email
        refute latest_user.global_admin
        refute latest_user.can_manage_web
        refute latest_user.can_manage_email
        refute latest_user.can_manage_users
        refute latest_user.can_manage_blog
      end
    end
  end
end
