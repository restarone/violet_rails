require "test_helper"

class ContentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:public)
  end

  test "should get index" do
    get root_path
    assert_response :success
    get root_path(subdomain: @customer.subdomain)
    assert_response :success
  end
end
