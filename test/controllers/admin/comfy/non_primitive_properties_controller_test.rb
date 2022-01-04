require "test_helper"

class Comfy::Admin::NonPrimitivePropertiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_web: true)
  end
    
  test "should not get index if not logged in" do
    get new_non_primitive_property_url
    assert_redirected_to new_user_session_url
  end
    
  test "should not get new if signed in but not allowed to manage web" do
    sign_in(@user)
    @user.update(can_manage_web: false)
    get new_non_primitive_property_url
    assert_response :redirect
  end

  test "should get new" do
    sign_in(@user)
    get new_non_primitive_property_url, xhr: true
    assert_response :success
  end
end
