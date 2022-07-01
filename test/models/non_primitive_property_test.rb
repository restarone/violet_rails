require "test_helper"

class NonPrimitivePropertyTest < ActiveSupport::TestCase
  test "should reset allow_attachments if field_type is not richtext" do
    non_primitive_property = non_primitive_properties(:one)
    non_primitive_property.update!(field_type: 'file')
    
    non_primitive_property.update!(allow_attachments: false)
    assert non_primitive_property.reload.allow_attachments
  end

  test "should not reset allow_attachments if field_type is richtext" do
    non_primitive_property = non_primitive_properties(:one)
    non_primitive_property.update!(field_type: 'richtext')
    
    expected_value = false
    non_primitive_property.update!(allow_attachments: expected_value)
    assert_equal expected_value, non_primitive_property.reload.allow_attachments
  end
end
