require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "returns only alphanumeric characters, underscores & slash(/) form the provided string by replacing '-' and spaces with underscore(_)" do
    string = 'test-string 12#test\2'

    expected_output = 'test_string_12test2'

    assert_equal expected_output, sanitize_recaptcha_action_name(string)
  end
end
