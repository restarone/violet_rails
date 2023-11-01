require "test_helper"

class Users::PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @root_user = users(:public)
    @root_subdomain = subdomains(:public)

    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
  end

  [:html, :turbo_stream].each do |request_format|
    # raised UnknownFormat Error when I tried to use format: :turbo_stream
    headers = { Accept: 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml', 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' } if request_format == :turbo_stream

    test "Request Format: #{request_format}, should send email for resetting password of the user in apex domain" do
      payload = {
        user: { email: @root_user.email }
      }
  
      Apartment::Tenant.switch(@root_subdomain.name) do
        assert_difference "Devise::Mailer.deliveries.size", +1 do
          post user_password_url(subdomain: Apartment::Tenant.current), params: payload, headers: headers
          assert_response :redirect
        end
  
        assert_match "<p><a href=\"http://localhost/users/password/edit", Devise::Mailer.deliveries.last.body.to_s
      end
    end
  
    test "Request Format: #{request_format}, should send email for resetting password of the user in subdomain" do
      Apartment::Tenant.switch(@restarone_subdomain.name) do
        payload = {
          user: { email: @restarone_user.email }
        }
  
        assert_difference "Devise::Mailer.deliveries.size", +1 do
          post user_password_url(subdomain: Apartment::Tenant.current), params: payload, headers: headers
          assert_response :redirect
        end
  
        assert_match "<p><a href=\"http://#{@restarone_subdomain.name}.", Devise::Mailer.deliveries.last.body.to_s
      end
    end
  
    test "Request Format: #{request_format}, should send email for resetting password of the user in apex domain using the current Apartment::Tenant instead of current Subdomain name" do
      previous_name = @root_subdomain.name
      @root_subdomain.update!(name: 'root')
  
      Apartment::Tenant.switch(previous_name) do
        payload = {
          user: { email: @root_user.email }
        }
  
        assert_difference "Devise::Mailer.deliveries.size", +1 do
          post user_password_url(subdomain: Apartment::Tenant.current), params: payload, headers: headers
          assert_response :redirect
        end
  
        current_apartment_tenant_name = Apartment::Tenant.current
        current_subdomain_name = @root_subdomain.name
  
        # no subdomain should be attached in url for 'public' tenant
        assert_match "<p><a href=\"http://localhost", Devise::Mailer.deliveries.last.body.to_s
        assert_no_match "<p><a href=\"http://#{current_apartment_tenant_name}.", Devise::Mailer.deliveries.last.body.to_s
      end
    end
  end
end
