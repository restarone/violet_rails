require "test_helper"

class Api::ResourceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_namespace = api_namespaces(:one)
    @users_namespace = api_namespaces(:users)
  end
  test 'describe resource name and version: get #index as json' do
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), as: :json
    assert_response :success
  end

  test 'describe resource name, version and ID: get #show as json' do
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug, id: '1'), as: :json
    assert_response :success
  end

  test 'does not render resource that requires authentication' do
    @api_namespace.update(requires_authentication: true)
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.slug), as: :json
    assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
  end

  test 'nonexistant resource results in 404' do
    get api_url(version: '1', api_namespace: 'usersd'), as: :json
    assert_equal({ status: 'not found', code: 404 }, response.parsed_body.symbolize_keys)
  end

  test 'describes resource' do
    get api_describe_url(version: @users_namespace.version, api_namespace: @users_namespace.slug)
    assert_equal response.parsed_body.symbolize_keys.keys.sort, [:created_at, :id, :name, :namespace_type, :properties, :requires_authentication, :slug, :updated_at, :version].sort 
  end

  test 'index users resource' do
    get api_url(version: @users_namespace.version, api_namespace: @users_namespace.slug), as: :json
    sample_user = response.parsed_body[0].symbolize_keys!
    assert_equal(
      [:id, :created_at, :properties, :updated_at].sort,
      sample_user.keys.sort
    )
    assert_equal sample_user[:properties].symbolize_keys!.keys.sort, api_resources(:user).properties.symbolize_keys!.keys.sort
  end

  test 'query users resource' do
    payload = {
      attribute: 'first_name',
      value: "Don"
    }
    post api_query_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, params: payload)
    sample_user = response.parsed_body[0].symbolize_keys!
    assert_equal(
      [:id, :created_at, :properties, :updated_at].sort,
      sample_user.keys.sort
    )
    assert_equal sample_user[:properties].symbolize_keys!.keys.sort, api_resources(:user).properties.symbolize_keys!.keys.sort
  end

  test '#show users resource' do
    get api_show_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal response.parsed_body.symbolize_keys.keys.sort, [:id, :created_at, :updated_at, :properties].sort
    assert_response :success
  end

  test '#create access is blocked by default for unsecured API' do
    refute @api_namespace.requires_authentication
    post api_create_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug)
    assert_no_difference "ApiResource.all.size" do
      assert_equal({ status: 'write access is disabled by default for public access namespaces', code: 403 }, response.parsed_body.symbolize_keys)
    end
  end

  test '#update access is blocked by default for unsecured API' do
    refute @api_namespace.requires_authentication
    patch api_update_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'write access is disabled by default for public access namespaces', code: 403 }, response.parsed_body.symbolize_keys)
  end

  test '#destroy access is blocked by default for unsecured API' do
    refute @api_namespace.requires_authentication
    delete api_destroy_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'write access is disabled by default for public access namespaces', code: 403 }, response.parsed_body.symbolize_keys)
  end

  test '#create access is blocked if bearer authentication is not provided' do
    @users_namespace.update(requires_authentication: true)
    post api_create_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug)
    assert_no_difference "ApiResource.all.size" do
      assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
    end
  end

  test '#update access is blocked if bearer authentication is not provided' do
    @users_namespace.update(requires_authentication: true)
    patch api_update_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
  end

  test '#destroy access is blocked if bearer authentication is not provided' do
    @users_namespace.update(requires_authentication: true)
    delete api_destroy_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
  end

  test '#create access is allowed if bearer authentication is provided' do
    @users_namespace.update(requires_authentication: true)
    api_client = api_clients(:for_users)
    payload = {
      data: {
        first_name: 'Don',
        last_name: 'Restarone'
      }
    }
    assert_difference "@users_namespace.api_resources.count", +1 do
      post api_create_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug), params: payload, headers: { 'Authorization': "Bearer #{api_client.bearer_token}" }
    end
    assert_equal [:status, :code, :object].sort, response.parsed_body.symbolize_keys.keys.sort
    assert_equal payload[:data].keys.sort, response.parsed_body["object"]["properties"].symbolize_keys.keys.sort

    assert_no_difference "@users_namespace.api_resources.count", +1 do
      post api_create_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug), headers: { 'Authorization': "Bearer #{api_client.bearer_token}" }
    end
    assert_equal [:status, :code].sort, response.parsed_body.symbolize_keys.keys.sort
    assert_equal response.parsed_body["status"], "Please make sure that your parameters are provided under a data: {} top-level key"
  end

  test '#update access is allowed if bearer authentication is provided' do
    @users_namespace.update(requires_authentication: true)
    api_client = api_clients(:for_users)
    payload = {
      data: {
        first_name: 'Don!',
        last_name: 'Restarone!'
      }
    }
    api_resource = @users_namespace.api_resources.first
    assert_not_equal api_resource.properties["first_name"], payload[:data][:first_name]
    cloned_before_state = api_resource.dup
    patch api_update_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: api_resource.id), params: payload, headers: { 'Authorization': "Bearer #{api_client.bearer_token}" }
    assert_equal [:status, :code, :object, :before].sort, response.parsed_body.symbolize_keys.keys.sort
    assert_equal api_resource.reload.properties["first_name"], response.parsed_body["object"]["properties"]["first_name"]
    assert_equal cloned_before_state.properties["first_name"], response.parsed_body["before"]["properties"]["first_name"]
    assert_equal payload[:data].keys.sort, response.parsed_body["object"]["properties"].symbolize_keys.keys.sort

    patch api_update_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: api_resource.id), headers: { 'Authorization': "Bearer #{api_client.bearer_token}" }
    assert_equal response.parsed_body["status"], "Please make sure that your parameters are provided under a data: {} top-level key"
  end

  test '#destroy access is allowed if bearer authentication is provided' do
    @users_namespace.update(requires_authentication: true)
    api_client = api_clients(:for_users)
    assert_difference "@users_namespace.api_resources.count", -1 do
      delete api_destroy_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.slug, api_resource_id: @users_namespace.api_resources.first.id), headers: { 'Authorization': "Bearer #{api_client.bearer_token}" }
    end
    assert_equal [:status, :code, :object].sort, response.parsed_body.symbolize_keys.keys.sort
  end
end
