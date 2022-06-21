require "test_helper"

class ApiResourceTest < ActiveSupport::TestCase
  test "when initialized - inherits parent properties" do
    api_namespace = api_namespaces(:one)
    api_resource = ApiResource.new(api_namespace_id: api_namespace.id)

    assert_equal api_resource.properties, api_namespace.properties
  end

  test "when updated - adheres to presence validations enforced by API form" do
    api_namespace = api_namespaces(:one)
    api_form = api_forms(:one)
    api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Name', 'field_type': 'input', 'required': '1' }})

    api_resource = ApiResource.create(api_namespace_id: api_namespace.id, properties: {'name': ''})
    refute api_resource.id

    assert_includes api_resource.errors.messages[:properties], 'name is required'
  end

  test "should set api_form's api_resource on initialization" do
    api_namespace = api_namespaces(:one)
    api_resource = ApiResource.new(api_namespace_id: api_namespace.id)

    assert_equal api_resource.api_namespace.api_form.api_resource, api_resource
  end
end
