require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  test "should create token before save" do
    api_key = ApiKey.new(authentication_strategy: 'bearer_token', label: 'test')
    refute api_key.token

    api_key.save!
    assert api_key.token
  end

  test "should not update token if token already exist" do
    api_key = ApiKey.new(authentication_strategy: 'bearer_token', label: 'test', token: 'test')
    assert_equal 'test', api_key.token

    api_key.save!
    assert_equal 'test', api_key.token
  end
end
