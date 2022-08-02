require "test_helper"

class ApiFormTest < ActiveSupport::TestCase
  test "return true if renderable property is nil" do
    api_form = api_forms(:one)
    assert api_form.is_field_renderable?('Test')
  end

  test "return true if renderable property is 1" do
    api_form = api_forms(:one)
    api_form.update(properties: { 'name': {'label': 'Test', 'placeholder': 'Test', 'field_type': 'input', 'renderable': '1' }})
    assert api_form.is_field_renderable?('Test')
  end

  test "return false if renderable property is 0" do
    api_form = api_forms(:one)
    api_form.update(properties: { 'name': {'label': 'Test', 'placeholder': 'Test', 'field_type': 'input', 'renderable': '0' }})
    assert api_form.is_field_renderable?('Test')
  end
  
  test "should not set both: show_recaptcha and show_recaptcha_v3" do
    api_form = api_forms(:one)
    api_form.update(show_recaptcha: true, show_recaptcha_v3: true)
    assert_equal true, api_form.show_recaptcha
    assert_equal false, api_form.show_recaptcha_v3
  end
end
