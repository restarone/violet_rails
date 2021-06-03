require "test_helper"

class Api::ResourceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_namespace = api_namespaces(:one)
  end
  test 'describe resource name and version: get #index as json' do
    get api_url(version: '1', api_namespace: 'users'), as: :json
    assert_response :success
  end

  test 'describe resource name, version and ID: get #show as json' do
    get api_url(version: '1', api_namespace: 'users', id: '1'), as: :json
    assert_response :success
  end

  test 'does not render resource that requires authentication' do
    @api_namespace.update(requires_authentication: true)
    get api_url(version: '1', api_namespace: 'users'), as: :json
    assert_equal({ status: 'unauthorized', code: 401 }, response.parsed_body.symbolize_keys)
  end

  test 'nonexistant resource results in 404' do
    get api_url(version: '1', api_namespace: 'usersd'), as: :json
    assert_equal({ status: 'not found', code: 404 }, response.parsed_body.symbolize_keys)
  end

  test 'describes resource' do
    get api_describe_url(version: '1', api_namespace: 'users')
    assert_equal response.parsed_body.symbolize_keys.keys.sort, [:id, :name, :version, :properties, :requires_authentication, :namespace_type, :created_at, :updated_at].sort 
  end
end
