require "test_helper"

class Comfy::Admin::ApiNamespacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_web: true)
    @api_namespace = api_namespaces(:one)
  end

  test "should not get index if not logged in" do
    get api_namespaces_url
    assert_redirected_to new_user_session_url
  end

  test "should not get index if signed in but not allowed to manage web" do
    sign_in(@user)
    @user.update(can_manage_web: false)
    get api_namespaces_url
    assert_response :redirect
  end

  test "should get index" do
    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  test "should get new" do
    sign_in(@user)
    get new_api_namespace_url
    assert_response :success
  end

  test "should create api_namespace" do
    sign_in(@user)
    assert_difference('ApiNamespace.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end

    assert_redirected_to api_namespace_url(ApiNamespace.last)
  end

  test "should show api_namespace" do
    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should get edit" do
    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should update api_namespace" do
    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_redirected_to api_namespace_url(@api_namespace)
  end

  test "should destroy api_namespace" do
    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end
end
