require "test_helper"

class Comfy::Admin::ApiFormsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_web: true)
    @api_namespace = api_namespaces(:one)
    @api_form = api_forms(:one)
  end


  test "should get edit" do
    sign_in(@user)
    get edit_api_namespace_api_form_url(api_namespace_id: @api_namespace.id, id: ApiForm.last.id)
    assert_response :success
  end

  test "should update api_form" do
    sign_in(@user)
    patch api_namespace_api_form_url(@api_form, api_namespace_id: @api_form.api_namespace_id), params: { api_form: { properties: @api_form.properties } }
    assert_redirected_to api_namespace_url(@api_form.api_namespace.slug)
  end

  test "should destroy api_form" do
    sign_in(@user)
    assert_difference('ApiForm.count', -1) do
      delete api_namespace_api_form_url(@api_form, api_namespace_id: @api_form.api_namespace_id)
    end
    assert_redirected_to api_namespace_url(@api_form.api_namespace.slug)
  end
end
