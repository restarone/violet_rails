require 'test_helper'

class ApiFormsHelperTest < ActionView::TestCase
  test 'renders api_form partial' do
    render_form(api_forms(:one))
    assert_template partial: "comfy/admin/api_forms/_render"
  end
end