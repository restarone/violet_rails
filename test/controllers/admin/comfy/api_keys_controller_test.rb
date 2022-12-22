require "test_helper"

class Comfy::Admin::ApiKeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {api_keys: {full_access: 'true'}})
    @api_key = api_keys(:one)
    @api_namespace = api_namespaces(:one)
  end

  test "should not get index if not authenticated" do
    get api_keys_url
    assert_redirected_to new_user_session_url
  end

  test "should not get #index, #new if signed in but does not have proper api-keys access" do
    sign_in(@user)
    @user.update(api_accessibility: {})
    get api_keys_url
    assert_response :redirect
    assert_equal "You do not have the permission to do that. Only users with full_access or read_access or delete_acess for ApiKeys are allowed to perform that action.", flash[:alert]

    get new_api_key_url
    assert_response :redirect
    assert_equal "You do not have the permission to do that. Only users with full_access for ApiKeys are allowed to perform that action.", flash[:alert]
  end

  test "should get index when user has proper api-key access" do
    ['full_access', 'delete_access', 'read_access'].each do |access_name|
      api_hash = {api_keys: {}}
      api_hash[:api_keys][access_name] = 'true'
      @user.update(api_accessibility: api_hash)

      sign_in(@user)
      get api_keys_url
      assert_response :success
    end
  end

  test "should get new when user has only full_access for api-key" do
    @user.update(api_accessibility: {api_keys: {full_access: 'true'}})
    sign_in(@user)
    get new_api_key_url
    assert_response :success
  end

  test "should deny new when user has only other accesses for api-key" do
    ['delete_access', 'read_access'].each do |access_name|
      api_hash = {api_keys: {}}
      api_hash[:api_keys][access_name] = 'true'
      @user.update(api_accessibility: api_hash)

      sign_in(@user)
      get new_api_key_url
      assert_response :redirect
      assert_equal "You do not have the permission to do that. Only users with full_access for ApiKeys are allowed to perform that action.", flash[:alert]
    end
  end

  test "should create api_key when user has full_access for api-keys" do
    @user.update(api_accessibility: {api_keys: {full_access: 'true'}})
    sign_in(@user)
    assert_difference('ApiKey.count', +1) do
      post api_keys_url, params: { api_key: {  authentication_strategy: @api_key.authentication_strategy, label: "foobar" } }
    end
    api_key = ApiKey.last
    assert_redirected_to api_key_path(id: api_key.id)
  end

  test "should deny create api_key when user has other accesses for api-key" do
    ['delete_access', 'read_access'].each do |access_name|
      api_hash = {api_keys: {}}
      api_hash[:api_keys][access_name] = 'true'
      @user.update(api_accessibility: api_hash)

      sign_in(@user)
      assert_no_difference('ApiKey.count') do
        post api_keys_url, params: { api_key: {  authentication_strategy: @api_key.authentication_strategy, label: "foobar" } }
      end
      
      assert_response :redirect
      assert_equal "You do not have the permission to do that. Only users with full_access for ApiKeys are allowed to perform that action.", flash[:alert]
    end
  end

  test "should show api_key when user has proper access for api-keys" do
    ['full_access', 'delete_access', 'read_access'].each do |access_name|
      api_hash = {api_keys: {}}
      api_hash[:api_keys][access_name] = 'true'
      @user.update(api_accessibility: api_hash)

      sign_in(@user)
      get api_key_url(id: @api_key.id)
      assert_response :success
      assert_template :show
    end
  end

  test "should get edit only when the user has full_access for api-key" do
    @user.update(api_accessibility: {api_keys: {full_access: 'true'}})
    sign_in(@user)
    get edit_api_key_path(id: @api_key.id)
    assert_response :success
    assert_template :edit
  end

  test "should deny edit when the user has other accesses for api-key" do
    ['delete_access', 'read_access'].each do |access_name|
      api_hash = {api_keys: {}}
      api_hash[:api_keys][access_name] = 'true'
      @user.update(api_accessibility: api_hash)

      sign_in(@user)
      get edit_api_key_path(id: @api_key.id)
      assert_response :redirect
      assert_equal "You do not have the permission to do that. Only users with full_access for ApiKeys are allowed to perform that action.", flash[:alert]
    end
  end

  test "should update api_key when the user has full_access for api-keys" do
    @user.update(api_accessibility: {api_keys: {full_access: 'true'}})
    sign_in(@user)
    patch api_key_url(id: @api_key.id), params: { api_key: { authentication_strategy: @api_key.authentication_strategy, label: @api_key.label } }
    assert_redirected_to api_key_url(id: @api_key.id)
  end

  test "should deny update api_key when the user has other accesses for api-keys" do
    ['delete_access', 'read_access'].each do |access_name|
      api_hash = {api_keys: {}}
      api_hash[:api_keys][access_name] = 'true'
      @user.update(api_accessibility: api_hash)

      sign_in(@user)
      patch api_key_url(id: @api_key.id), params: { api_key: { authentication_strategy: @api_key.authentication_strategy, label: @api_key.label } }
      assert_response :redirect
      assert_equal "You do not have the permission to do that. Only users with full_access for ApiKeys are allowed to perform that action.", flash[:alert]
    end
  end

  test "should destroy api_key when user has full_access for api-keys" do
    @user.update(api_accessibility: {api_keys: {full_access: 'true'}})

    sign_in(@user)
    assert_difference('ApiKey.count', -1) do
      delete api_key_url(id: @api_key.id)
    end

    assert_redirected_to api_keys_url
  end

  test "should destroy api_key when user has delete_access for api-keys" do
    @user.update(api_accessibility: {api_keys: {delete_access: 'true'}})

    sign_in(@user)
    assert_difference('ApiKey.count', -1) do
      delete api_key_url(id: @api_key.id)
    end

    assert_redirected_to api_keys_url
  end

  test "should deny destroy api_key when user has read_access for api-keys" do
    @user.update(api_accessibility: {api_keys: {read_access: 'true'}})

    sign_in(@user)
    assert_no_difference('ApiKey.count') do
      delete api_key_url(id: @api_key.id)
    end

    assert_response :redirect
    assert_equal "You do not have the permission to do that. Only users with full_access or delete_access for ApiKeys are allowed to perform that action.", flash[:alert]
  end
end
