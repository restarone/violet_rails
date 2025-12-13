require "test_helper"

class NonPrimitivePropertyTest < ActiveSupport::TestCase
  def setup
    @api_namespace = api_namespaces(:one)
    @non_primitive_property = NonPrimitiveProperty.new(
      label: "Test Property",
      field_type: :richtext,
      content: "Test content",
      api_namespace: @api_namespace
    )
  end

  test "should be valid with all attributes" do
    assert @non_primitive_property.valid?
  end

  test "should validate presence of label" do
    @non_primitive_property.label = nil
    assert_not @non_primitive_property.valid?
    assert_includes @non_primitive_property.errors[:label], "can't be blank"
  end

  test "should belong to api_resource optionally" do
    assert_respond_to @non_primitive_property, :api_resource
    assert_respond_to @non_primitive_property, :api_resource=
  end

  test "should belong to api_namespace optionally" do
    assert_respond_to @non_primitive_property, :api_namespace
    assert_equal @api_namespace, @non_primitive_property.api_namespace
  end

  test "should have field_type enum" do
    assert_respond_to @non_primitive_property, :field_type
    assert_equal 0, NonPrimitiveProperty.field_types[:file]
    assert_equal 1, NonPrimitiveProperty.field_types[:richtext]
  end

  test "should have rich text content" do
    assert_respond_to @non_primitive_property, :content
    assert_respond_to @non_primitive_property, :rich_text_content
  end

  test "should have attachment" do
    assert_respond_to @non_primitive_property, :attachment
  end

  test "should respond to file_url method" do
    assert_respond_to @non_primitive_property, :file_url
  end

  test "should identify file type correctly" do
    @non_primitive_property.field_type = :file
    assert @non_primitive_property.file?
    assert_not @non_primitive_property.richtext?
  end

  test "should identify richtext type correctly" do
    @non_primitive_property.field_type = :richtext
    assert @non_primitive_property.richtext?
    assert_not @non_primitive_property.file?
  end
end
