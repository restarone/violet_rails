require "test_helper"
# require 'minitest/stub_any_instance'

class Comfy::Admin::ApiClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
    @api_client = api_clients(:one)
    @api_namespace = api_namespaces(:one)
  end

  test "should not get index if not authenticated" do
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_redirected_to new_user_session_url
  end

  test "should not get #index, #new if signed in but not allowed to manage web" do
    sign_in(@user)
    @user.update(api_accessibility: {})
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect
    get new_api_namespace_api_client_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect
  end

  test "should only show api_clients of specified api_namespace" do
    # Creating new api_clients of @api_namespace
    @api_client.dup.save!
    @api_client.dup.save!

    # Creating another api_namespace and its api_clients
    new_api_namespace = api_namespaces(:two)
    new_api_client = api_clients(:two)
    new_api_client.dup.save!
    new_api_client.dup.save!

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :success

    @controller.view_assigns['api_clients'].each do |api_client|
      assert_equal api_client.api_namespace_id, @api_namespace.id
    end

    assert_not_includes @controller.view_assigns['api_clients'].pluck(:api_namespace_id), new_api_namespace.id
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

  # SHOW
  # API access for all namespaces
  test 'should get show if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :show
  end

  test 'should get show if user has full_read_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_read_access: 'true'}}})

    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :show
  end

  test 'should get show if user has full_access_for_api_clients_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_clients_only: 'true'}}})

    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :show
  end

  test 'should get show if user has read_api_clients_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_api_clients_only: 'true'}}})

    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :show
  end

  test 'should not get show if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {allow_duplication: 'true'}}})

    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_clients_only or read_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get show if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :show
  end

  test 'should get show if user has full_read_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :show
  end

  test 'should get show if user has full_access_for_api_clients_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :show
  end

  test 'should get show if user has read_api_clients_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_api_clients_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :show
  end

  test 'should get show if user has read_api_clients_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {read_api_clients_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :show
  end

  test 'should not get show if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_duplication: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_clients_only or read_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # INDEX
  # API access for all namespaces
  test 'should get index if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has full_read_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_read_access: 'true'}}})

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has full_access_for_api_clients_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_clients_only: 'true'}}})

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has read_api_clients_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_api_clients_only: 'true'}}})

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should not get index if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {allow_duplication: 'true'}}})

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_clients_only or read_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get index if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has full_read_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has full_access_for_api_clients_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has read_api_clients_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_api_clients_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has read_api_clients_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {read_api_clients_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should not get index if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_duplication: 'true'}}}})

    sign_in(@user)
    get api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_clients_only or read_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # NEW
  # API access for all_namespaces
  test 'should get new if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    get new_api_namespace_api_client_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get new if user has full_access_for_api_clients_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_clients_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_api_client_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should not get new if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_api_clients_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_api_client_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get new if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_api_client_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get new if user has full_access_for_api_clients_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_api_client_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get new if user has read_api_clients_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_api_client_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should not get new if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_api_clients_only: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_api_client_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # EDIT
  # API access for all_namespaces
  test 'should get edit if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_api_client_path(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :edit
  end

  test 'should get edit if user has full_access_for_api_clients_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_clients_only: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_api_client_path(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :edit
  end

  test 'should not get edit if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_api_clients_only: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_api_client_path(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get edit if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_api_client_path(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :edit
  end

  test 'should get edit if user has full_access_for_api_clients_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_api_client_path(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :edit
  end

  test 'should get edit if user has read_api_clients_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_api_client_path(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :success
    assert_template :edit
  end

  test 'should not get edit if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_api_clients_only: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_api_client_path(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # CREATE
  # API access for all_namespaces
  test 'should get create if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    assert_difference('ApiClient.count') do
      post api_namespace_api_clients_url(api_namespace_id: @api_namespace.id), params: { api_client: {  authentication_strategy: @api_client.authentication_strategy, label: "foobar" } }
    end
    api_client = ApiClient.last
    assert_redirected_to api_namespace_api_client_path(api_namespace_id: api_client.api_namespace.id, id: api_client.id)
  end

  test 'should get create if user has full_access_for_api_clients_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_clients_only: 'true'}}})

    sign_in(@user)
    assert_difference('ApiClient.count') do
      post api_namespace_api_clients_url(api_namespace_id: @api_namespace.id), params: { api_client: {  authentication_strategy: @api_client.authentication_strategy, label: "foobar" } }
    end
    api_client = ApiClient.last
    assert_redirected_to api_namespace_api_client_path(api_namespace_id: api_client.api_namespace.id, id: api_client.id)
  end

  test 'should not get create if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_api_clients_only: 'true'}}})

    sign_in(@user)
    assert_no_difference('ApiClient.count') do
      post api_namespace_api_clients_url(api_namespace_id: @api_namespace.id), params: { api_client: {  authentication_strategy: @api_client.authentication_strategy, label: "foobar" } }
    end
    api_client = ApiClient.last
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get create if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    assert_difference('ApiClient.count') do
      post api_namespace_api_clients_url(api_namespace_id: @api_namespace.id), params: { api_client: {  authentication_strategy: @api_client.authentication_strategy, label: "foobar" } }
    end
    api_client = ApiClient.last
    assert_redirected_to api_namespace_api_client_path(api_namespace_id: api_client.api_namespace.id, id: api_client.id)
  end

  test 'should get create if user has full_access_for_api_clients_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    assert_difference('ApiClient.count') do
      post api_namespace_api_clients_url(api_namespace_id: @api_namespace.id), params: { api_client: {  authentication_strategy: @api_client.authentication_strategy, label: "foobar" } }
    end
    api_client = ApiClient.last
    assert_redirected_to api_namespace_api_client_path(api_namespace_id: api_client.api_namespace.id, id: api_client.id)
  end

  test 'should get create if user has read_api_clients_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    assert_difference('ApiClient.count') do
      post api_namespace_api_clients_url(api_namespace_id: @api_namespace.id), params: { api_client: {  authentication_strategy: @api_client.authentication_strategy, label: "foobar" } }
    end
    api_client = ApiClient.last
    assert_redirected_to api_namespace_api_client_path(api_namespace_id: api_client.api_namespace.id, id: api_client.id)
  end

  test 'should not get create if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_api_clients_only: 'true'}}}})

    sign_in(@user)
    assert_no_difference('ApiClient.count') do
      post api_namespace_api_clients_url(api_namespace_id: @api_namespace.id), params: { api_client: {  authentication_strategy: @api_client.authentication_strategy, label: "foobar" } }
    end
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # UPDATE
  # API access for all_namespaces
  test 'should get update if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    patch api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id), params: { api_client: { authentication_strategy: @api_client.authentication_strategy, bearer_token: @api_client.bearer_token, label: @api_client.label } }
    assert_redirected_to api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
  end

  test 'should get update if user has full_access_for_api_clients_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_clients_only: 'true'}}})

    sign_in(@user)
    patch api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id), params: { api_client: { authentication_strategy: @api_client.authentication_strategy, bearer_token: @api_client.bearer_token, label: @api_client.label } }
    assert_redirected_to api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
  end

  test 'should not get update if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_api_clients_only: 'true'}}})

    sign_in(@user)
    patch api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id), params: { api_client: { authentication_strategy: @api_client.authentication_strategy, bearer_token: @api_client.bearer_token, label: @api_client.label } }
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get update if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    patch api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id), params: { api_client: { authentication_strategy: @api_client.authentication_strategy, bearer_token: @api_client.bearer_token, label: @api_client.label } }
    assert_redirected_to api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
  end

  test 'should get update if user has full_access_for_api_clients_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    patch api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id), params: { api_client: { authentication_strategy: @api_client.authentication_strategy, bearer_token: @api_client.bearer_token, label: @api_client.label } }
    assert_redirected_to api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
  end

  test 'should get update if user has read_api_clients_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    patch api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id), params: { api_client: { authentication_strategy: @api_client.authentication_strategy, bearer_token: @api_client.bearer_token, label: @api_client.label } }
    assert_redirected_to api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
  end

  test 'should not get update if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_api_clients_only: 'true'}}}})

    sign_in(@user)
    patch api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id), params: { api_client: { authentication_strategy: @api_client.authentication_strategy, bearer_token: @api_client.bearer_token, label: @api_client.label } }
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # DESTROY
  # API access for all_namespaces
  test 'should destroy if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    assert_difference('ApiClient.count', -1) do
      delete api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    end

    assert_redirected_to api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
  end

  test 'should destroy if user has full_access_for_api_clients_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_clients_only: 'true'}}})

    sign_in(@user)
    assert_difference('ApiClient.count', -1) do
      delete api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    end

    assert_redirected_to api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
  end

  test 'should not destroy if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_api_clients_only: 'true'}}})

    sign_in(@user)
    assert_no_difference('ApiClient.count') do
      delete api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should destroy if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    assert_difference('ApiClient.count', -1) do
      delete api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    end

    assert_redirected_to api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
  end

  test 'should destroy if user has full_access_for_api_clients_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    assert_difference('ApiClient.count', -1) do
      delete api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    end

    assert_redirected_to api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
  end

  test 'should destroy if user has read_api_clients_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_api_clients_only: 'true'}}}})

    sign_in(@user)
    assert_difference('ApiClient.count', -1) do
      delete api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    end

    assert_redirected_to api_namespace_api_clients_url(api_namespace_id: @api_namespace.id)
  end

  test 'should not destroy if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_api_clients_only: 'true'}}}})

    sign_in(@user)
    assert_no_difference('ApiClient.count') do
      delete api_namespace_api_client_url(api_namespace_id: @api_client.api_namespace.id, id: @api_client.id)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_clients_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

end
