require "test_helper"

class Comfy::Admin::ApiKeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_api: true)
    @api_key = api_keys(:one)
    @api_namespace = api_namespaces(:one)
  end

  test "should not get index if not authenticated" do
    get api_keys_url
    assert_redirected_to new_user_session_url
  end

  test "should not get #index, #new if signed in but not allowed to manage web" do
    sign_in(@user)
    @user.update(can_manage_api: false)
    get api_keys_url
    assert_response :redirect
    get new_api_key_url
    assert_response :redirect
  end

  test "should get index" do
    sign_in(@user)
    get api_keys_url
    assert_response :success
  end

  test "should get new" do
    sign_in(@user)
    get new_api_key_url
    assert_response :success
  end

  test "should create api_key" do
    sign_in(@user)
    assert_difference('ApiKey.count') do
      post api_keys_url, params: { api_key: {  authentication_strategy: @api_key.authentication_strategy, label: "foobar" } }
    end
    api_key = ApiKey.last
    assert_redirected_to api_key_path(id: api_key.id)
  end

  test "should show api_key" do
    sign_in(@user)
    get api_key_url(id: @api_key.id)
    assert_response :success
    assert_template :show
  end

  test "should get edit" do
    sign_in(@user)
    get edit_api_key_path(id: @api_key.id)
    assert_response :success
    assert_template :edit
  end

  test "should update api_key" do
    sign_in(@user)
    patch api_key_url(id: @api_key.id), params: { api_key: { authentication_strategy: @api_key.authentication_strategy, label: @api_key.label } }
    assert_redirected_to api_key_url(id: @api_key.id)
  end

  test "should destroy api_key" do
    sign_in(@user)
    assert_difference('ApiKey.count', -1) do
      delete api_key_url(id: @api_key.id)
    end

    assert_redirected_to api_keys_url
  end
end
