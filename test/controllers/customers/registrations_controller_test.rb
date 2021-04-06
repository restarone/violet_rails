require "test_helper"

class Customers::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:public)
    @restarone_customer = Customer.find_by(subdomain: 'restarone')
  end

  test "should initialize tenant schema and public site" do
    payload = {
      sign_up: {
        subdomain: 'tester',
        email: 'test@tester.com',
        password: '123456',
        password_confirmation: '123456'
      }
    }
    assert_difference "Customer.all.reload.size", +1 do
      Apartment::Tenant.switch(Customer.last.subdomain) do
        assert_difference "Comfy::Cms::Site.all.reload.size", +1 do
          post customer_registration_path, params: payload
        end
      end
    end
  end
end
