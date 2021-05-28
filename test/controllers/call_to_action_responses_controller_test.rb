require "test_helper"

class CallToActionResponsesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @call_to_action = call_to_actions(:one)
    @call_to_action.call_to_action_responses.destroy_all
  end

  test "#respond" do
    payload = {
      call_to_action: {
        call_to_action_response: {
          email: 'foo@bar.com',
          name: 'foobar'
        }
      }
    }
    assert_difference "CallToActionResponse.all.reload.size", +1 do
      refute @call_to_action.call_to_action_responses.reload.first
      post respond_call_to_action_path(@call_to_action), params: payload
      assert flash.notice
      call_to_action_response = @call_to_action.call_to_action_responses.reload.first
      assert_equal call_to_action_response.properties["email"], payload[:call_to_action][:call_to_action_response][:email]
      assert_equal call_to_action_response.properties["name"], payload[:call_to_action][:call_to_action_response][:name]
    end
  end
end
