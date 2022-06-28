require "test_helper"

class NonPrimitivePropertyTest < ActiveSupport::TestCase
  test "should reset disable_file_attachment if field_type is not richtext" do
    non_primitive_property = non_primitive_properties(:one)
    non_primitive_property.update!(field_type: 'file')
    
    non_primitive_property.update!(disable_file_attachment: true)
    refute non_primitive_property.reload.disable_file_attachment
  end

  test "should not reset disable_file_attachment if field_type is richtext" do
    non_primitive_property = non_primitive_properties(:one)
    non_primitive_property.update!(field_type: 'richtext')
    
    expected_value = true
    non_primitive_property.update!(disable_file_attachment: expected_value)
    assert_equal expected_value, non_primitive_property.reload.disable_file_attachment
  end
end
