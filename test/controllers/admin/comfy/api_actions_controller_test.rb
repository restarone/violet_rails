require "test_helper"

class Comfy::Admin::ApiActionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})
    @api_namespace = api_namespaces(:one)
    @api_action = api_actions(:one)
  end

  test "should not get #index, #new, #show if signed in but not allowed to manage api" do
    @user.update(api_accessibility: {})
    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :redirect
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :redirect
    get api_namespace_api_action_url(@api_action, api_namespace_id: @api_action.api_namespace_id)
    assert_response :redirect
  end

  test "should get new" do
    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
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

  # SHOW
  # API access for all_namespaces
  test 'should get show if user has full_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :success
  end

  test 'should get show if user has full_read_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_read_access: 'true'}})

    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :success
  end

  test 'should get show if user has full_access_for_api_actions_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_actions_only: 'true'}})

    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :success
  end

  test 'should get show if user has read_api_actions_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_actions_only: 'true'}})

    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :success
  end

  test 'should not get show if user has other access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {allow_duplication: 'true'}})

    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_actions_only or read_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get show if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :success
  end

  test 'should get show if user has full_read_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}})

    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :success
  end

  test 'should get show if user has full_access_for_api_actions_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_for_api_actions_only: 'true'}}})

    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :success
  end

  test 'should get show if user has read_api_actions_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_actions_only: 'true'}}})

    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :success
  end

  test 'should get show if user has read_api_actions_only for the uncategorized namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {read_api_actions_only: 'true'}}})

    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :success
  end

  test 'should not get show if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_duplication: 'true'}}})

    sign_in(@user)
    api_action = api_actions(:two)
    get api_namespace_api_action_url(api_action, api_namespace_id: api_action.api_resource.api_namespace_id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_actions_only or read_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # INDEX
  # API access for all_namespaces
  test 'should get index if user has full_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
  end

  test 'should get index if user has full_read_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_read_access: 'true'}})

    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
  end

  test 'should get index if user has full_access_for_api_actions_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_actions_only: 'true'}})

    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
  end

  test 'should get index if user has read_api_actions_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_actions_only: 'true'}})

    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
  end

  test 'should not get index if user has other access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {allow_duplication: 'true'}})

    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_actions_only or read_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get index if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
  end

  test 'should get index if user has full_read_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}})

    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
  end

  test 'should get index if user has full_access_for_api_actions_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_for_api_actions_only: 'true'}}})

    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
  end

  test 'should get index if user has read_api_actions_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_actions_only: 'true'}}})

    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
  end

  test 'should get index if user has read_api_actions_only for the uncategorized namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {read_api_actions_only: 'true'}}})

    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
  end

  test 'should not get index if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_duplication: 'true'}}})

    sign_in(@user)
    get api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_actions_only or read_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # NEW
  # API access for all_namespaces
  test 'should get new if user has full_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :success
  end

  test 'should get new if user has full_access_for_api_actions_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_actions_only: 'true'}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :success
  end

  test 'should not get new if user has other access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_actions_only: 'true'}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get new if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :success
  end

  test 'should get new if user has full_access_for_api_actions_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_for_api_actions_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :success
  end

  test 'should get new if user has read_api_actions_only for the uncategorized namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {full_access_for_api_actions_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :success
  end

  test 'should not get new if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_actions_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # EDIT
  # API access for all_namespaces
  test 'should get edit if user has full_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :success
  end

  test 'should get edit if user has full_access_for_api_actions_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_actions_only: 'true'}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :success
  end

  test 'should not get edit if user has other access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_actions_only: 'true'}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get edit if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :success
  end

  test 'should get edit if user has full_access_for_api_actions_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_for_api_actions_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :success
  end

  test 'should get edit if user has read_api_actions_only for the uncategorized namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {full_access_for_api_actions_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :success
  end

  test 'should not get edit if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_actions_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_api_action_url(api_namespace_id: @api_action.api_namespace_id, index: 1, type: 'new_api_actions'), xhr: true
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # ACTION_WORKFLOW
  # API access for all_namespaces
  test 'should get action_workflow if user has full_access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    get action_workflow_api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
    # '+' button should be shown to add new api-action form
    assert_select "a[data-action-workflow='add-new-api-action-form']"
    # 'x' button should be shown to remove existing api-action
    assert_select "a[data-action-workflow='remove-api-action']"
  end

  test 'should get action_workflow if user has full_access_for_api_actions_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_actions_only: 'true'}})

    sign_in(@user)
    get action_workflow_api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
    # '+' button should be shown to add new api-action form
    assert_select "a[data-action-workflow='add-new-api-action-form']"
    # 'x' button should be shown to remove existing api-action
    assert_select "a[data-action-workflow='remove-api-action']"
  end

  test 'should get action_workflow if user has read_api_actions_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_actions_only: 'true'}})

    sign_in(@user)
    get action_workflow_api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
    # '+' button should not be shown to add new api-action form
    assert_select "a[data-action-workflow='add-new-api-action-form']", {count: 0}
    # 'x' button should not be shown to remove existing api-action
    assert_select "a[data-action-workflow='remove-api-action']", {count: 0}
  end

  test 'should not get action_workflow if user has other access for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_resources_only: 'true'}})

    sign_in(@user)
    get action_workflow_api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_actions_only or read_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test 'should update action_workflow if user has full_access_for_api_actions_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_actions_only: 'true'}})

    payload = {
      api_namespace: {
        create_api_actions_attributes: {
          "0": {
            action_type: "send_email",
            include_api_resource_data: "true",
            email: "test@restarone.com",
            email_subject: "Test",
            custom_message: "<div class=\"trix-content\">Test email</div>\r\n",
            redirect_type: "cms_page",
            redirect_url: "", 
            file_snippet: "",
            request_url: "",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "0"
          },
          "1": {
            action_type: "send_web_request",
            include_api_resource_data: "false",
            email: "",
            email_subject: "",
            custom_message: "<div class=\"trix-content\"></div>",
            redirect_type: "cms_page",
            redirect_url: "",
            file_snippet: "",
            request_url: "https://api.spotify.com/v1/search",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "1"
          }
        }
      }
    }

    sign_in(@user)
    assert_difference "@api_action.api_namespace.create_api_actions.count", 2 do
      patch api_action_workflow_api_namespace_url(id: @api_action.api_namespace_id), params: payload
    end

    assert_response :redirect
    expected_message = 'Action Workflow successfully updated.'
    assert_equal expected_message, flash[:notice]
  end

  test 'should not update action_workflow if user has read_api_actions_only for all namespace' do
    @user.update(api_accessibility: {all_namespaces: {read_api_actions_only: 'true'}})

    payload = {
      api_namespace: {
        create_api_actions_attributes: {
          "0": {
            action_type: "send_email",
            include_api_resource_data: "true",
            email: "test@restarone.com",
            email_subject: "Test",
            custom_message: "<div class=\"trix-content\">Test email</div>\r\n",
            redirect_type: "cms_page",
            redirect_url: "", 
            file_snippet: "",
            request_url: "",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "0"
          },
          "1": {
            action_type: "send_web_request",
            include_api_resource_data: "false",
            email: "",
            email_subject: "",
            custom_message: "<div class=\"trix-content\"></div>",
            redirect_type: "cms_page",
            redirect_url: "",
            file_snippet: "",
            request_url: "https://api.spotify.com/v1/search",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "1"
          }
        }
      }
    }

    sign_in(@user)
    assert_no_difference "@api_action.api_namespace.create_api_actions.count" do
      patch api_action_workflow_api_namespace_url(id: @api_action.api_namespace_id), params: payload
    end

    assert_response :redirect
    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
      assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get action_workflow if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    get action_workflow_api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
    # '+' button should be shown to add new api-action form
    assert_select "a[data-action-workflow='add-new-api-action-form']"
    # 'x' button should be shown to remove existing api-action
    assert_select "a[data-action-workflow='remove-api-action']"
  end

  test 'should get action_workflow if user has full_access_for_api_actions_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_for_api_actions_only: 'true'}}})

    sign_in(@user)
    get action_workflow_api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
    # '+' button should be shown to add new api-action form
    assert_select "a[data-action-workflow='add-new-api-action-form']"
    # 'x' button should be shown to remove existing api-action
    assert_select "a[data-action-workflow='remove-api-action']"
  end

  test 'should get action_workflow if user has full_access_for_api_actions_only for the uncategorized namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {full_access_for_api_actions_only: 'true'}}})

    sign_in(@user)
    get action_workflow_api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
    # '+' button should be shown to add new api-action form
    assert_select "a[data-action-workflow='add-new-api-action-form']"
    # 'x' button should be shown to remove existing api-action
    assert_select "a[data-action-workflow='remove-api-action']"
  end

  test 'should get action_workflow if user has read_api_actions_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_actions_only: 'true'}}})

    sign_in(@user)
    get action_workflow_api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :success
    # '+' button should not be shown to add new api-action form
    assert_select "a[data-action-workflow='add-new-api-action-form']", {count: 0}
    # 'x' button should not be shown to remove existing api-action
    assert_select "a[data-action-workflow='remove-api-action']", {count: 0}
  end

  test 'should not get action_workflow if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_resources_only: 'true'}}})

    sign_in(@user)
    get action_workflow_api_namespace_api_actions_url(api_namespace_id: @api_action.api_namespace_id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_actions_only or read_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test 'should update action_workflow if user has category-specific full_access_for_api_actions_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_for_api_actions_only: 'true'}}})

    payload = {
      api_namespace: {
        create_api_actions_attributes: {
          "0": {
            action_type: "send_email",
            include_api_resource_data: "true",
            email: "test@restarone.com",
            email_subject: "Test",
            custom_message: "<div class=\"trix-content\">Test email</div>\r\n",
            redirect_type: "cms_page",
            redirect_url: "", 
            file_snippet: "",
            request_url: "",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "0"
          },
          "1": {
            action_type: "send_web_request",
            include_api_resource_data: "false",
            email: "",
            email_subject: "",
            custom_message: "<div class=\"trix-content\"></div>",
            redirect_type: "cms_page",
            redirect_url: "",
            file_snippet: "",
            request_url: "https://api.spotify.com/v1/search",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "1"
          }
        }
      }
    }

    sign_in(@user)
    assert_difference "@api_action.api_namespace.create_api_actions.count", 2 do
      patch api_action_workflow_api_namespace_url(id: @api_action.api_namespace_id), params: payload
    end

    assert_response :redirect
    expected_message = 'Action Workflow successfully updated.'
    assert_equal expected_message, flash[:notice]
  end

  test 'should not update action_workflow if user has category-specific read_api_actions_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {read_api_actions_only: 'true'}}})

    payload = {
      api_namespace: {
        create_api_actions_attributes: {
          "0": {
            action_type: "send_email",
            include_api_resource_data: "true",
            email: "test@restarone.com",
            email_subject: "Test",
            custom_message: "<div class=\"trix-content\">Test email</div>\r\n",
            redirect_type: "cms_page",
            redirect_url: "", 
            file_snippet: "",
            request_url: "",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "0"
          },
          "1": {
            action_type: "send_web_request",
            include_api_resource_data: "false",
            email: "",
            email_subject: "",
            custom_message: "<div class=\"trix-content\"></div>",
            redirect_type: "cms_page",
            redirect_url: "",
            file_snippet: "",
            request_url: "https://api.spotify.com/v1/search",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "1"
          }
        }
      }
    }

    sign_in(@user)
    assert_no_difference "@api_action.api_namespace.create_api_actions.count" do
      patch api_action_workflow_api_namespace_url(id: @api_action.api_namespace_id), params: payload
    end

    assert_response :redirect
    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
      assert_equal expected_message, flash[:alert]
  end

  test 'should update action_workflow if user has uncategorized full_access_for_api_actions_only for the namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {full_access_for_api_actions_only: 'true'}}})

    payload = {
      api_namespace: {
        create_api_actions_attributes: {
          "0": {
            action_type: "send_email",
            include_api_resource_data: "true",
            email: "test@restarone.com",
            email_subject: "Test",
            custom_message: "<div class=\"trix-content\">Test email</div>\r\n",
            redirect_type: "cms_page",
            redirect_url: "", 
            file_snippet: "",
            request_url: "",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "0"
          },
          "1": {
            action_type: "send_web_request",
            include_api_resource_data: "false",
            email: "",
            email_subject: "",
            custom_message: "<div class=\"trix-content\"></div>",
            redirect_type: "cms_page",
            redirect_url: "",
            file_snippet: "",
            request_url: "https://api.spotify.com/v1/search",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "1"
          }
        }
      }
    }

    sign_in(@user)
    assert_difference "@api_action.api_namespace.create_api_actions.count", 2 do
      patch api_action_workflow_api_namespace_url(id: @api_action.api_namespace_id), params: payload
    end

    assert_response :redirect
    expected_message = 'Action Workflow successfully updated.'
    assert_equal expected_message, flash[:notice]
  end

  test 'should not update action_workflow if user has uncategorized read_api_actions_only for the namespace' do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {read_api_actions_only: 'true'}}})

    payload = {
      api_namespace: {
        create_api_actions_attributes: {
          "0": {
            action_type: "send_email",
            include_api_resource_data: "true",
            email: "test@restarone.com",
            email_subject: "Test",
            custom_message: "<div class=\"trix-content\">Test email</div>\r\n",
            redirect_type: "cms_page",
            redirect_url: "", 
            file_snippet: "",
            request_url: "",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "0"
          },
          "1": {
            action_type: "send_web_request",
            include_api_resource_data: "false",
            email: "",
            email_subject: "",
            custom_message: "<div class=\"trix-content\"></div>",
            redirect_type: "cms_page",
            redirect_url: "",
            file_snippet: "",
            request_url: "https://api.spotify.com/v1/search",
            http_method: "get",
            payload_mapping: "{}",
            custom_headers: "{}",
            bearer_token: "[FILTERED]",
            method_definition: "raise StandardError",
            "_destroy": "false",
            position: "1"
          }
        }
      }
    }

    sign_in(@user)
    assert_no_difference "@api_action.api_namespace.create_api_actions.count" do
      patch api_action_workflow_api_namespace_url(id: @api_action.api_namespace_id), params: payload
    end

    assert_response :redirect
    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
      assert_equal expected_message, flash[:alert]
  end
end
