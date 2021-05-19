require "test_helper"

class ContentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
  end

  test "should get index" do
    get root_url
    assert_response :success
    get root_url(subdomain: @restarone_user.subdomain)
    assert_response :success
  end
end
