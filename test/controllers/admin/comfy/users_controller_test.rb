require "test_helper"

class Comfy::Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:public)
    @public_subdomain = @customer.subdomains.first
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    @restarone_customer = @restarone_subdomain.customer
    @user = users(:public)
  end

  test "get #index by authorized personnel" do
    sign_in(@user)
    get users_url(subdomain: @public_subdomain.name)
    assert_response :success
    assert_template :index
  end
end
