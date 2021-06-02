require "test_helper"

class Api::ResourceControllerTest < ActionDispatch::IntegrationTest
  
  test 'describe resource name and version: get #index as json' do
    get api_resource_index_path(version: 'v1', api_namespace: 'users'), as: :json
    assert_response :success
  end

  test 'describe resource name, version and ID: get #show as json' do
    get api_resource_index_path(version: 'v1', api_namespace: 'users', id: '1'), as: :json
    assert_response :success
  end
end
