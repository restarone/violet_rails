require "test_helper"

class Comfy::Admin::ApiClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_web: true)
    @api_client = api_clients(:one)
    @api_namespace = api_namespaces(:one)
  end

  test "should not get index if not authenticated" do
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_redirected_to new_user_session_url
  end

  test "should not get #index, #new if signed in but not allowed to manage web" do
    sign_in(@user)
    @user.update(can_manage_web: false)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect
    get new_api_namespace_api_client_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect
  end

  test "should get index" do
    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test "should get new" do
    sign_in(@user)
    get new_api_namespace_api_client_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test "should create api_client" do
    sign_in(@user)
    assert_difference('ApiClient.count') do
      post api_namespace_api_clients_url(api_namespace_id: @api_namespace.id), params: { api_client: {  authentication_strategy: @api_client.authentication_strategy, label: "foobar" } }
    end
    api_client = ApiClient.last
    assert_redirected_to api_namespace_api_client_path(api_namespace_id: api_client.api_namespace.id, id: api_client.id)
  end

  test "should show api_client" do
    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :show
  end

  test "should get edit" do
    sign_in(@user)
    get edit_api_namespace_api_client_path(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :edit
  end

  test "should update api_client" do
    sign_in(@user)
    patch api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id), params: { api_client: { authentication_strategy: @api_client.authentication_strategy, bearer_token: @api_client.bearer_token, label: @api_client.label } }
    assert_redirected_to api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
  end

  test "should destroy api_client" do
    sign_in(@user)
    assert_difference('ApiClient.count', -1) do
      delete api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    end

    assert_redirected_to api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
  end
end
