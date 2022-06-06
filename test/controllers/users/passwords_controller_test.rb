require "test_helper"

class Users::PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @root_user = users(:public)
    @root_subdomain = subdomains(:public)

    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
  end

  test "should send email for resetting password of the user" do
    payload = {
      user: { email: @root_user.email }
    }

    Apartment::Tenant.switch(@root_subdomain.name) do
      post user_password_url(subdomain: Apartment::Tenant.current), params: payload
      byebug
      assert_response :redirect
    end
  end
end
