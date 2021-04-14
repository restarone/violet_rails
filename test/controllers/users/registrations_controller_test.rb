require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @public_subdomain = @user.subdomain
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
  end

  test "should not allow create (within subdomain scope)" do
    subdomain = 'tester'
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
      assert_no_difference "User.all.reload.size", +1 do
        post user_registration_url(subdomain: @public_subdomain), params: payload
        assert_response :redirect
        assert_redirected_to signup_wizard_index_path
      end
    end

    Apartment::Tenant.switch(@restarone_subdomain) do
      assert_no_difference "User.all.reload.size" do
        post user_registration_url(subdomain: @restarone_subdomain), params: payload
        assert_response :redirect
        assert_redirected_to signup_wizard_index_path
      end
    end
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

  test "should initialize tenant schema and public site (along with default layout, page and fragment) and send email confirmation (within subdomain scope)" do
    skip
    subdomain = 'tester'
    email = 'test@tester.com'
    password = '123456'
    payload = {
      user: {
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    Subdomain.create! name: subdomain
    assert_changes "Devise.mailer.deliveries.size" do          
      post user_registration_url(subdomain: subdomain), params: payload
      assert_response :redirect
      assert_redirected_to root_url(subdomain: subdomain)
      Apartment::Tenant.switch(subdomain) do
        public_site = Comfy::Cms::Site.find_by(hostname: Subdomain.find_by(name: subdomain).hostname)
        assert public_site
        default_layout = public_site.layouts.first
        assert default_layout
        default_page = default_layout.pages.first
        assert default_page
        assert default_page.fragments.any?
      end
    end
  end
end
