require "test_helper"

class ApiFormTest < ActiveSupport::TestCase
  test "return true if renderable property is nil" do
    api_form = api_forms(:one)
    assert api_form.is_field_renderable?('Test')
  end

  test "return true if renderable property is 1" do
    api_form = api_forms(:renderable)
    assert api_form.is_field_renderable?('Test')
  end

  test "return false if renderable property is 0" do
    api_form = api_forms(:non_renderable)
    assert api_form.is_field_renderable?('Test')
  end
end
