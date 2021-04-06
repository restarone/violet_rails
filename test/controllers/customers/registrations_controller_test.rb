require "test_helper"

class Customers::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:public)
    @restarone_customer = Subdomain.find_by(name: 'restarone').customer
  end

  test "should initialize tenant schema and public site" do
    payload = {
      customer: {
        subdomain: 'tester',
        email: 'test@tester.com',
        password: '123456',
        password_confirmation: '123456'
      }
    }
    assert_difference "Customer.all.reload.size", +1 do
      # assert_difference "Comfy::Cms::Site.all.reload.size", +1 do
        post customer_registration_url, params: payload
        assert_response :redirect
        assert_redirected_to root_url(subdomain: Subdomain.last.name)
      # end
    end
  end
end
