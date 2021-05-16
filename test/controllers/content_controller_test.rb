require "test_helper"

class ContentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
  end

  test "should get index" do
    get root_url
    assert_response :success
    get root_url(subdomain: @user.subdomain)
    assert_response :success
  end
end
