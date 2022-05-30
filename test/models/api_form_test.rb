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

  test "success_message_has_html? returns true if success message contains valid html" do
    api_form = api_forms(:one)
    api_form.update(success_message: '<div>Test</div>')
    assert api_form.success_message_has_html?
  end

  test "success_message_has_html? returns false if success message contains invalid html" do
    api_form = api_forms(:one)
    api_form.update(success_message: '<div>Test>')
    refute api_form.success_message_has_html?
  end

  test "success_message_has_html? returns false if success message has no html" do
    api_form = api_forms(:one)
    api_form.update(success_message: 'Test')
    refute api_form.success_message_has_html?
  end

  test "failure_message_has_html? returns true if failure message contains valid html" do
    api_form = api_forms(:one)
    api_form.update(failure_message: '<div>Test</div>')
    assert api_form.failure_message_has_html?
  end

  test "failure_message_has_html? returns false if failure message contains invalid html" do
    api_form = api_forms(:one)
    api_form.update(failure_message: '<div>Test>')
    refute api_form.failure_message_has_html?
  end

  test "failure_message_has_html? returns false if failure message has no html" do
    api_form = api_forms(:one)
    api_form.update(failure_message: 'Test')
    refute api_form.failure_message_has_html?
  end

  test "failure_message_has_html? returns false if failure message is nil" do
    api_form = api_forms(:one)
    api_form.update(failure_message: nil)
    refute api_form.failure_message_has_html?
  end
end
