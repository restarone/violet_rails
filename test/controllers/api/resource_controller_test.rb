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
    get api_describe_url(version: '1', api_namespace: @api_namespace.name)
    assert_equal response.parsed_body.symbolize_keys.keys.sort, [:created_at, :id, :name, :namespace_type, :properties, :requires_authentication, :slug, :updated_at, :version].sort 
  end

  test 'index users resource' do
    get api_url(version: '1', api_namespace: @users_namespace.name), as: :json
    sample_user = response.parsed_body[0].symbolize_keys!
    assert_equal(
      [:id, :api_namespace_id, :properties, :created_at, :updated_at].sort,
      sample_user.keys.sort
    )
    assert_equal JSON.parse(sample_user[:properties]).symbolize_keys!.keys.sort, JSON.parse(api_resources(:user).properties).symbolize_keys!.keys.sort
  end
end
