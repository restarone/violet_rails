require "test_helper"

class ContentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:public)
  end

  test "should get index" do
    get root_url
    assert_response :success
    get root_url(subdomain: @customer.subdomain)
    assert_response :success
  end
end
