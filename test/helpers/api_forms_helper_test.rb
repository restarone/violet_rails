require 'test_helper'

class ApiFormsHelperTest < ActionView::TestCase
  test 'renders api_form partial' do
    render_form(api_forms(:one))
    assert_template partial: "comfy/admin/api_forms/_render"
  end

  test 'renders radio button partial when input type is radio and select_type is single' do
    resp = render_form(api_forms(:two)).to_s
    assert_includes(resp, 'type="radio"')
    refute_includes(resp, 'type="checkbox"')
    assert_template partial: "comfy/admin/api_forms/_radio"
  end

  test 'renders radio partial with checkboxes when input type is radio and select_type is multi' do
    resp = render_form(api_forms(:three)).to_s
    refute_includes(resp, 'type="radio"')
    assert_includes(resp, 'type="checkbox"')
    assert_template partial: "comfy/admin/api_forms/_radio"
  end
end