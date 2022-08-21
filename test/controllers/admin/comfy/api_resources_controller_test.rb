require "test_helper"

class Comfy::Admin::ApiResourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_api: true)
    @api_namespace = api_namespaces(:one)
    @api_resource = api_resources(:one)

    Sidekiq::Testing.fake!
  end

  test "should get new" do
    sign_in(@user)
    get new_api_namespace_resource_url(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test "should create api_resource" do
    sign_in(@user)
    payload_as_stringified_json = "{\"age\":26,\"alive\":true,\"last_name\":\"Teng\",\"first_name\":\"Jennifer\"}"

    redirect_action = @api_namespace.create_api_actions.where(action_type: 'redirect').last
    redirect_action.update(redirect_url: '/')

    perform_enqueued_jobs do
      assert_difference('ApiResource.count') do
        post api_namespace_resources_url(api_namespace_id: @api_namespace.id), params: { api_resource: { properties: payload_as_stringified_json } }
        Sidekiq::Worker.drain_all
      end
    end

    assert ApiResource.last.properties
    assert_equal JSON.parse(payload_as_stringified_json).symbolize_keys.keys, ApiResource.last.properties.symbolize_keys.keys
    assert_equal "window.location.replace('#{redirect_action.redirect_url}')", response.parsed_body
  end

  test "should show api_resource" do
    sign_in(@user)
    get api_namespace_resource_url(api_namespace_id: @api_namespace.id, id: @api_namespace.api_resources.sample.id)
    assert_response :success
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
end
