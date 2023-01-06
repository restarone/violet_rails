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

  test 'should update incomplete api actions when parent action is updated' do
    api_namespace_action = api_actions(:create_api_action_one)
    api_resource = api_resources(:one)
    api_resource_action = api_resource.create_api_actions.create(api_namespace_action.attributes.merge('lifecycle_stage' => 'initialized', parent_id: api_namespace_action.id).except("id", "created_at", "updated_at", "api_namespace_id"))

    assert_equal api_namespace_action.email, api_resource_action.email

    api_namespace_action.update(email: 'test@random.com')

    assert_equal 'test@random.com', api_resource_action.reload.email
  end

  test 'should not update completed api actions when parent action is updated' do
    api_namespace_action = api_actions(:create_api_action_one)
    api_resource = api_resources(:one)
    api_resource_action = api_resource.create_api_actions.create(api_namespace_action.attributes.merge('lifecycle_stage' => 'complete', parent_id: api_namespace_action.id).except("id", "created_at", "updated_at", "api_namespace_id"))

    assert_equal api_namespace_action.email, api_resource_action.email

    api_namespace_action.update(email: 'test@random.com')

    refute_equal 'test@random.com', api_resource_action.reload.email
  end

  test "should rerun with new code when api action is updated" do
    api_namespace = api_namespaces(:one)

    custom_action = api_actions(:create_api_action_one).dup
    custom_action.action_type = "custom_action"
    custom_action.method_definition = "1'+2"
    custom_action.save!

    assert_difference 'CreateApiAction.count', +api_namespace.reload.create_api_actions.count do
      @api_resource = ApiResource.create!(api_namespace_id: api_namespace.id, properties: {'name': 'John Doe'})
    end

    api_action = @api_resource.create_api_actions.find_by(action_type: 'custom_action')

    assert_raises SyntaxError do
      api_action.reload.execute_action(true)
    end

    custom_action.update(method_definition: "1+2")

    assert_changes -> { api_action.reload.lifecycle_stage }, to: 'complete' do
      api_action.reload.execute_action(true)
    end
  end
end
