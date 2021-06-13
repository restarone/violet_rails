require "test_helper"

class Api::ResourceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_namespace = api_namespaces(:one)
    @users_namespace = api_namespaces(:users)
  end
  test 'describe resource name and version: get #index as json' do
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.name), as: :json
    assert_response :success
  end

  test 'describe resource name, version and ID: get #show as json' do
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.name, id: '1'), as: :json
    assert_response :success
  end

  test 'does not render resource that requires authentication' do
    @api_namespace.update(requires_authentication: true)
    get api_url(version: @api_namespace.version, api_namespace: @api_namespace.name), as: :json
    assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
  end

  test 'nonexistant resource results in 404' do
    get api_url(version: '1', api_namespace: 'usersd'), as: :json
    assert_equal({ status: 'not found', code: 404 }, response.parsed_body.symbolize_keys)
  end

  test 'describes resource' do
    get api_describe_url(version: @users_namespace.version, api_namespace: @users_namespace.name)
    assert_equal response.parsed_body.symbolize_keys.keys.sort, [:created_at, :id, :name, :namespace_type, :properties, :requires_authentication, :slug, :updated_at, :version].sort 
  end

  test 'index users resource' do
    get api_url(version: @users_namespace.version, api_namespace: @users_namespace.name), as: :json
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
    post api_query_url(version: @users_namespace.version, api_namespace: @users_namespace.name, params: payload)
    sample_user = response.parsed_body[0].symbolize_keys!
    assert_equal(
      [:id, :created_at, :properties, :updated_at].sort,
      sample_user.keys.sort
    )
    assert_equal sample_user[:properties].symbolize_keys!.keys.sort, api_resources(:user).properties.symbolize_keys!.keys.sort
  end

  test '#show users resource' do
    get api_show_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.name, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal response.parsed_body.symbolize_keys.keys.sort, [:id, :created_at, :updated_at, :properties].sort
    assert_response :success
  end

  test '#create access is blocked by default for unsecured API' do
    refute @api_namespace.requires_authentication
    post api_create_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.name)
    assert_no_difference "ApiResource.all.size" do
      assert_equal({ status: 'write access is disabled by default for public access namespaces', code: 403 }, response.parsed_body.symbolize_keys)
    end
  end

  test '#update access is blocked by default for unsecured API' do
    refute @api_namespace.requires_authentication
    patch api_update_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.name, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'write access is disabled by default for public access namespaces', code: 403 }, response.parsed_body.symbolize_keys)
  end

  test '#destroy access is blocked by default for unsecured API' do
    refute @api_namespace.requires_authentication
    delete api_destroy_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.name, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'write access is disabled by default for public access namespaces', code: 403 }, response.parsed_body.symbolize_keys)
  end

  test '#create access is blocked if bearer authentication is not provided' do
    @users_namespace.update(requires_authentication: true)
    post api_create_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.name)
    assert_no_difference "ApiResource.all.size" do
      assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
    end
  end

  test '#update access is blocked if bearer authentication is not provided' do
    @users_namespace.update(requires_authentication: true)
    patch api_update_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.name, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
  end

  test '#destroy access is blocked if bearer authentication is not provided' do
    @users_namespace.update(requires_authentication: true)
    delete api_destroy_resource_url(version: @users_namespace.version, api_namespace: @users_namespace.name, api_resource_id: @users_namespace.api_resources.first.id)
    assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
  end
end
