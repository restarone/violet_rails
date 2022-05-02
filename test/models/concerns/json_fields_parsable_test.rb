require "test_helper"

class JsonbFieldsParsableTest < ActiveSupport::TestCase
    test "should convert JSON string into hash for all jsonb fields before save" do
      api_namespace = ApiNamespace.create(name: 'test 123', version: 1, properties: {name: 'test'}.to_json)
      assert api_namespace.properties.is_a?(Hash)

      api_resource = ApiResource.create(api_namespace_id: api_namespace.id, properties: {can_edit: true, can_delete: true}.to_json)
      assert api_resource.properties.is_a?(Hash)

      api_action = CreateApiAction.create(api_resource_id: api_resource.id, action_type: 'send_web_request', payload_mapping: {"first_name":"test"}.to_json, custom_headers: {"AUTHORIZATION":"SECRET_BEARER_TOKEN"}.to_json)
      assert api_action.payload_mapping.is_a?(Hash)
      assert api_action.custom_headers.is_a?(Hash)

      api_form = ApiForm.create(api_namespace_id: api_namespace.id, properties: { 'name': {'label': 'Test', 'placeholder': 'Test', 'field_type': 'input' }}.to_json)
      assert api_form.properties.is_a?(Hash)


      external_api_client = ExternalApiClient.create(api_namespace_id: api_namespace.id, slug: 'test-api', label: 'test', metadata: {"api_key": "x-api-key-foo", "bearer_token": "foo"}.to_json)
      assert external_api_client.metadata.is_a?(Hash)
    end

    test "should not convert to hash if value is already a hash" do
        api_namespace = ApiNamespace.create(name: 'test 123', version: 1, properties: {name: 'test'})
        assert api_namespace.properties.is_a?(Hash)
  
        api_resource = ApiResource.create(api_namespace_id: api_namespace.id, properties: {can_edit: true, can_delete: true})
        assert api_resource.properties.is_a?(Hash)
  
        api_action = CreateApiAction.create(api_resource_id: api_resource.id, action_type: 'send_web_request', payload_mapping: {"first_name":"test"}, custom_headers: {"AUTHORIZATION":"SECRET_BEARER_TOKEN"})
        assert api_action.payload_mapping.is_a?(Hash)
        assert api_action.custom_headers.is_a?(Hash)
  
        api_form = ApiForm.create(api_namespace_id: api_namespace.id, properties: { 'name': {'label': 'Test', 'placeholder': 'Test', 'field_type': 'input' }})
        assert api_form.properties.is_a?(Hash)
  
  
        external_api_client = ExternalApiClient.create(api_namespace_id: api_namespace.id, slug: 'test-api', label: 'test', metadata: {"api_key": "x-api-key-foo", "bearer_token": "foo"})
        assert external_api_client.metadata.is_a?(Hash)
    end

    test "should add validation error if value is invalid JSON string" do
        namespace = api_namespaces(:one)

        api_namespace = ApiNamespace.create(name: 'test 123', version: 1, properties: "{name: 'test'}")
        refute api_namespace.id
        assert_equal api_namespace.errors[:properties][0], "Invalid Json Format"
  
        api_resource = ApiResource.create(api_namespace_id: namespace.id, properties: "{can_edit: true can_delete: true}")
        refute api_resource.id
        assert_equal api_resource.errors[:properties][0], "Invalid Json Format"
  
        api_action = CreateApiAction.create(api_namespace_id: namespace.id, action_type: 'send_web_request', payload_mapping: "Invalid JSON")
        refute api_action.id
        assert_equal api_action.errors[:payload_mapping][0], "Invalid Json Format"
  
        api_form = ApiForm.create(api_namespace_id: namespace.id, properties: "{ 'name': {'label': 'Test', 'placeholder': 'Test', 'field_type': 'input' }}")
        refute api_form.id
        assert_equal api_form.errors[:properties][0], "Invalid Json Format"
  
        external_api_client = ExternalApiClient.create(api_namespace_id: namespace.id, slug: 'test-api', label: 'test', metadata: "invalid json")
        refute external_api_client.id
        assert_equal external_api_client.errors[:metadata][0], "Invalid Json Format"
    end
end
