require "test_helper"

class Comfy::Admin::ApiActionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_api: true)
    @api_namespace = api_namespaces(:one)
    @api_action = api_actions(:one)
  end

  test "should not get #index, #new, #show if signed in but not allowed to manage api" do
    @user.update(can_manage_api: false)
    sign_in(@user)
    get new_api_action_url(index: 1, type: 'new_api_actions'), xhr: true
    assert_response :redirect
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :redirect
    get api_namespace_api_action_url(@api_action, api_namespace_id: @api_action.api_namespace_id)
    assert_response :redirect
  end

  test "should get new" do
    sign_in(@user)
    get new_api_action_url(index: 1, type: 'new_api_actions'), xhr: true
    assert_response :success
  end

  test "should get index" do
    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
  end

  test "should get show" do
    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :success
  end

  test "should get action_workflow" do
    sign_in(@user)
    get action_workflow_api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
  end
end
