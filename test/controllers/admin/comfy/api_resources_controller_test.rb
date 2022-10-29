require "test_helper"

class Comfy::Admin::ApiResourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})
    @api_namespace = api_namespaces(:one)
    @api_resource = api_resources(:one)

    Sidekiq::Testing.fake!
  end

  test "should get new" do
    sign_in(@user)
    get new_api_namespace_resource_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test "deny new if not permissioned" do
    @user.update(api_accessibility: {all_namespaces: {full_read_access: 'true'}})
    sign_in(@user)
    get new_api_namespace_resource_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect
    assert_equal "You do not have the permission to do that. Only users with full_access or full_access_for_api_resources_only are allowed to perform that action.", flash[:alert]
  end

  test "should create api_resource" do
    sign_in(@user)
    payload_as_stringified_json = "{\"age\":26,\"alive\":true,\"last_name\":\"Teng\",\"first_name\":\"Jennifer\"}"

    redirect_action = @api_namespace.create_api_actions.where(action_type: 'redirect').last
    redirect_action.update(redirect_url: '/')

    @api_namespace.api_form.update(success_message: 'test success message')

    perform_enqueued_jobs do
      assert_difference('ApiResource.count') do
        post api_namespace_resources_url(api_namespace_id: @api_namespace.id), params: { api_resource: { properties: payload_as_stringified_json } }
        Sidekiq::Worker.drain_all
      end
    end

    assert ApiResource.last.properties
    assert_equal JSON.parse(payload_as_stringified_json).symbolize_keys.keys, ApiResource.last.properties.symbolize_keys.keys
    assert_redirected_to '/'
    
    # ApiForm's custom success-message is not shown when the form is submitted by from admin-side.
    refute_equal'test success message', flash[:notice]
  end

  test "should show api_resource" do
    @api_namespace.api_form.update(success_message: 'test success message')
    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success

    # ApiForm's custom success-message is not shown when viewed from admin-side.
    refute_equal'test success message', flash[:notice]
  end

  test "should get edit" do
    sign_in(@user)
    get edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test "should update api_resource" do
    sign_in(@user)
    perform_enqueued_jobs do
      patch api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id), params: { api_resource: { properties: @api_resource.properties } }, headers: { 'HTTP_REFERER': edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id) }
      Sidekiq::Worker.drain_all
    end
    assert_redirected_to edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id)
    assert_equal 'Api resource was successfully updated.', flash[:notice]
  end

  test "should update api_resource and redirect properly according to defined redirect-api-action" do
    @api_namespace.api_form.update(success_message: 'test success message')

    redirect_action = @api_resource.update_api_actions.create!(action_type: 'redirect', redirect_url: root_url)

    sign_in(@user)
    perform_enqueued_jobs do
      patch api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id), params: { api_resource: { properties: @api_resource.properties } }, headers: { 'HTTP_REFERER': edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id) }
      Sidekiq::Worker.drain_all
    end

    assert_redirected_to root_url
    # ApiForm's custom success-message is not shown when viewed from admin-side.
    refute_equal 'test success message', flash[:notice]
  end

  test "should execute failed response api_resource" do
    sign_in(@user)

    actions_count = @api_resource.api_namespace.error_api_actions.size
    perform_enqueued_jobs do
      assert_raises StandardError do
        patch api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id), params:  { properties: @api_resource.properties }, headers: { 'HTTP_REFERER': edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id) }
        Sidekiq::Worker.drain_all
        assert_equal @api_resource.error_api_actions.count, actions_count
      end
    end
  end

  test "should destroy api_resource" do
    sign_in(@user)
    assert_difference('ApiResource.count', -1) do
      delete api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id)
    end
    assert_redirected_to api_namespace_url(id: @api_namespace.id)
  end

  # SHOW
  # API access for all namespaces
  test 'should get show if user has full_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should get show if user has full_read_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_read_access: 'true'}})

    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should get show if user has full_access_for_api_resources_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should get show if user has read_api_resources_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_resources_only: 'true'}})

    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should not get show if user has other access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {allow_duplication: 'true'}})

    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_resources_only or read_api_resources_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get show if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should get show if user has full_read_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}})

    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should get show if user has full_access_for_api_resources_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should get show if user has read_api_resources_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_resources_only: 'true'}}})

    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should get show if user has read_api_resources_only for the uncategorized namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {read_api_resources_only: 'true'}}})

    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should not get show if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_duplication: 'true'}}})

    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_resources_only or read_api_resources_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # NEW
  # API access for all_namespaces
  test 'should get new if user has full_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    get new_api_namespace_resource_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get new if user has full_access_for_api_resources_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

    sign_in(@user)
    get new_api_namespace_resource_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should not get new if user has other access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_resources_only: 'true'}})

    sign_in(@user)
    get new_api_namespace_resource_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_resources_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get new if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    get new_api_namespace_resource_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get new if user has full_access_for_api_resources_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_resource_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get new if user has read_api_resources_only for the uncategorized namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_resource_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should not get new if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_resources_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_resource_url(api_namespace_id: @api_namespace.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_resources_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # EDIT
  # API access for all_namespaces
  test 'should get edit if user has full_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    get edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should get edit if user has full_access_for_api_resources_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

    sign_in(@user)
    get edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should not get edit if user has other access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_resources_only: 'true'}})

    sign_in(@user)
    get edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_resources_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get edit if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should get edit if user has full_access_for_api_resources_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should get edit if user has read_api_resources_only for the uncategorized namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
  end

  test 'should not get edit if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_resources_only: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_resources_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # UPDATE
  # API access for all_namespaces
  test 'should get update if user has full_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    perform_enqueued_jobs do
      patch api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id), params: { api_resource: { properties: @api_resource.properties } }, headers: { 'HTTP_REFERER': edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id) }
      Sidekiq::Worker.drain_all
    end
    assert_redirected_to edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id)
  end

  test 'should get update if user has full_access_for_api_resources_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

    sign_in(@user)
    perform_enqueued_jobs do
      patch api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id), params: { api_resource: { properties: @api_resource.properties } }, headers: { 'HTTP_REFERER': edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id) }
      Sidekiq::Worker.drain_all
    end
    assert_redirected_to edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id)
  end

  test 'should not get update if user has other access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_resources_only: 'true'}})

    sign_in(@user)
    perform_enqueued_jobs do
      patch api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id), params: { api_resource: { properties: @api_resource.properties } }, headers: { 'HTTP_REFERER': edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id) }
      Sidekiq::Worker.drain_all
    end
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_resources_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get update if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    perform_enqueued_jobs do
      patch api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id), params: { api_resource: { properties: @api_resource.properties } }, headers: { 'HTTP_REFERER': edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id) }
      Sidekiq::Worker.drain_all
    end
    assert_redirected_to edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id)
  end

  test 'should get update if user has full_access_for_api_resources_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    perform_enqueued_jobs do
      patch api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id), params: { api_resource: { properties: @api_resource.properties } }, headers: { 'HTTP_REFERER': edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id) }
      Sidekiq::Worker.drain_all
    end
    assert_redirected_to edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id)
  end

  test 'should get update if user has read_api_resources_only for the uncategorized namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    perform_enqueued_jobs do
      patch api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id), params: { api_resource: { properties: @api_resource.properties } }, headers: { 'HTTP_REFERER': edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id) }
      Sidekiq::Worker.drain_all
    end
    assert_redirected_to edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id)
  end

  test 'should not get update if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_resources_only: 'true'}}})

    sign_in(@user)
    perform_enqueued_jobs do
      patch api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id), params: { api_resource: { properties: @api_resource.properties } }, headers: { 'HTTP_REFERER': edit_api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_resource.id) }
      Sidekiq::Worker.drain_all
    end
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_resources_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # DESTROY
  # API access for all_namespaces
  test 'should destroy if user has full_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    assert_difference('ApiResource.count', -1) do
      delete api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id)
    end
    assert_redirected_to api_namespace_url(id: @api_namespace.id)
  end

  test 'should destroy if user has full_access_for_api_resources_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

    sign_in(@user)
    assert_difference('ApiResource.count', -1) do
      delete api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id)
    end
    assert_redirected_to api_namespace_url(id: @api_namespace.id)
  end

  test 'should destroy if user has delete_access_for_api_resources_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {delete_access_for_api_resources_only: 'true'}})

    sign_in(@user)
    assert_difference('ApiResource.count', -1) do
      delete api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id)
    end
    assert_redirected_to api_namespace_url(id: @api_namespace.id)
  end

  test 'should not destroy if user has other access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_resources_only: 'true'}})

    sign_in(@user)
    assert_no_difference('ApiResource.count') do
      delete api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_resources_only or delete_access_for_api_resources_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should destroy if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    assert_difference('ApiResource.count', -1) do
      delete api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id)
    end
    assert_redirected_to api_namespace_url(id: @api_namespace.id)
  end

  test 'should destroy if user has full_access_for_api_resources_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    assert_difference('ApiResource.count', -1) do
      delete api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id)
    end
    assert_redirected_to api_namespace_url(id: @api_namespace.id)
  end

  test 'should destroy if user has delete_access_for_api_resources_only for the uncategorized namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {delete_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    assert_difference('ApiResource.count', -1) do
      delete api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id)
    end
    assert_redirected_to api_namespace_url(id: @api_namespace.id)
  end

  test 'should not destroy if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_resources_only: 'true'}}})

    sign_in(@user)
    assert_no_difference('ApiResource.count') do
      delete api_namespace_resource_url(@api_resource, api_namespace_id: @api_resource.api_namespace_id)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_resources_only or delete_access_for_api_resources_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end
end
