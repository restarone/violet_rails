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

  test "should store the parsed-response" do
    json_response = {success: 'true', message: 'success'}
    stub_request(:post, "www.example.com/success").to_return(body: JSON.generate(json_response), status: 200, headers: {'Content-Type': 'application/json'})

    api_action = api_actions(:create_api_action_three)
    api_action.update(bearer_token: 'test')
    api_action.execute_action

    assert_equal api_action.reload.lifecycle_stage, 'complete'
    assert_equal api_action.reload.lifecycle_message, json_response.to_json
  end

  test 'should respond to dynamically generated method' do
    api_resource = api_resources(:one)

    expected_response = {
      email_subject: "API Resource Accessed #{api_resource.id}",
      custom_message: "<div class=\"trix-content\">\n  API Namespace Accessed #{api_resource.api_namespace.id}\n</div>\n",
      request_url: "API Resource Property Accessed  #{api_resource.properties['can_edit']}",
      payload_mapping: {
        test_key: "#{api_resource.id}"
  }.to_json
    }

    api_action = ApiAction.new(
      api_resource_id: api_resource.id,
      email_subject: "API Resource Accessed \#{api_resource.id}",
      custom_message: "API Namespace Accessed \#{api_resource.api_namespace.id}",
      request_url: "API Resource Property Accessed  \#{api_resource.properties['can_edit']}",
      payload_mapping: {
        test_key: "\#{api_resource.id}"
      }
    )
    assert api_action.valid?
    [:email_subject, :custom_message, :request_url, :payload_mapping].each do |dynamic_attr|
      assert_respond_to api_action, "#{dynamic_attr}_evaluated".to_sym
      assert_equal api_action.send("#{dynamic_attr}_evaluated".to_sym), expected_response[dynamic_attr]
    end
  end

  test 'should raise error if unsafe string is evaluted' do
    api_resource = api_resources(:one)

    api_action = ApiAction.new(
      api_resource_id: api_resource.id,
      email_subject: "API Resource Accessed \#{api_resource.id}",
      custom_message: "API Namespace Accessed \#{api_resource.api_namespace.id}",
      request_url: "API Resource Property Accessed  \#{api_resource.properties['can_edit']}",
      email: "test\#{api_resource.id}@test.com",
      payload_mapping: {
        test_key: "\#{User.destroy_all}"
      }
    )
    refute api_action.valid?

    [:email, :email_subject, :custom_message, :request_url, :payload_mapping].each do |dynamic_attr|
      assert_raises ActiveRecord::RecordInvalid do
        api_action.send("#{dynamic_attr}_evaluated".to_sym)
      end
    end
  end
end
