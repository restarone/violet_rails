require "test_helper"

class ApiActionTest < ActiveSupport::TestCase
  test "should store success response" do
    api_action = api_actions(:create_api_action_three)
    api_action.update(bearer_token: 'test')
    api_action.execute_action

    assert_equal api_action.reload.lifecycle_stage, 'complete'
    assert_equal api_action.reload.lifecycle_message, 'success response'
  end

  test "should store error response" do
    api_action = api_actions(:create_api_action_four)
    api_action.update(bearer_token: 'test')
    api_action.execute_action

    assert_equal api_action.reload.lifecycle_stage, 'failed'
    assert_equal api_action.reload.lifecycle_message, 'error response'
  end
end
