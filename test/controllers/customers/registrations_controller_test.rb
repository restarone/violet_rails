require "test_helper"

class Customers::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:public)
    @restarone_customer = Subdomain.find_by(name: 'restarone').customer
  end

  test "should initialize tenant schema and public site (along with default layout, page and fragment) and send email confirmation" do
    subdomain = 'tester'
    email = 'test@tester.com'
    password = '123456'
    payload = {
      customer: {
        subdomain: subdomain,
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    assert_difference "Customer.all.reload.size", +1 do
      assert_difference "Subdomain.all.reload.size", +1 do        
        assert_changes "Devise.mailer.deliveries.size" do          
          post customer_registration_url, params: payload
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
  end
end
