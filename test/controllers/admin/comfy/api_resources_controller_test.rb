require "test_helper"

class ApiResourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_web: true)
    @api_namespace = api_namespaces(:one)
    @api_resource = api_resources(:one)
  end

  test "should not get index if not logged in" do
    get api_namespace_resources_url(api_namespace_id: @api_namespace.id)
    assert_redirected_to new_user_session_url
  end

  test "should not get index if signed in but not allowed to manage web" do
    sign_in(@user)
    @user.update(can_manage_web: false)
    get api_namespace_resources_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect
  end

  test "should get index" do
    get api_namespace_resources_url
    assert_response :success
  end

  test "should get new" do
    get new_namespace_api_resource_url
    assert_response :success
  end

  test "should create api_resource" do
    assert_difference('ApiResource.count') do
      post api_namespace_resources_url, params: { api_resource: { api_namespace_id: @api_resource.api_namespace_id, properties: @api_resource.properties } }
    end

    assert_redirected_to api_resource_url(ApiResource.last)
  end

  test "should show api_resource" do
    get api_namespace_resource_url(@api_resource)
    assert_response :success
  end

  test "should get edit" do
    get edit_namespace_api_resource_url(@api_resource)
    assert_response :success
  end

  test "should update api_resource" do
    patch api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id), params: { api_resource: { properties: @api_resource.properties } }
    assert_redirected_to api_namespace_resource_url(@api_resource)
  end

  test "should destroy api_resource" do
    assert_difference('ApiResource.count', -1) do
      delete api_namespace_resource_url(@api_resource)
    end

    assert_redirected_to api_resources_url
  end
end
