require "test_helper"

class CallToActionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_web: true)
    @call_to_action = call_to_actions(:one)
  end

  test "should not get index if not logged in" do
    get call_to_actions_url
    assert_redirected_to new_user_session_url
  end

  test "should not get index if signed in but not allowed to manage web" do
    sign_in(@user)
    @user.update(can_manage_web: false)
    get call_to_actions_url
    assert_response :redirect
  end

  test "should get new" do
    sign_in(@user)
    get new_call_to_action_url
    assert_response :success
  end

  test "should create call_to_action" do
    sign_in(@user)
    assert_difference('CallToAction.count') do
      post call_to_actions_url, params: { call_to_action: { cta_type: @call_to_action.cta_type, title: @call_to_action.title } }
    end

    assert_redirected_to call_to_action_url(CallToAction.last)
  end

  test "should show call_to_action" do
    sign_in(@user)
    get call_to_action_url(@call_to_action)
    assert_response :success
  end

  test "should get edit" do
    sign_in(@user)
    get edit_call_to_action_url(@call_to_action)
    assert_response :success
  end

  test "should update call_to_action" do
    sign_in(@user)
    patch call_to_action_url(@call_to_action), params: { call_to_action: { cta_type: @call_to_action.cta_type, title: @call_to_action.title } }
    assert_redirected_to call_to_action_url(@call_to_action)
  end

  test "should destroy call_to_action" do
    sign_in(@user)
    assert_difference('CallToAction.count', -1) do
      delete call_to_action_url(@call_to_action)
    end

    assert_redirected_to call_to_actions_url
  end
end
