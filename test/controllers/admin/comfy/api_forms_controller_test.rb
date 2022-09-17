require "test_helper"

class Comfy::Admin::ApiFormsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @api_namespace = api_namespaces(:one)
    @api_form = api_forms(:one)
  end


  test "should get edit if permissioned" do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})
    sign_in(@user)

    get edit_api_namespace_api_form_url(api_namespace_id: @api_namespace.id, id: ApiForm.last.id)
    assert_response :success

    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_form_only: 'true'}})
    get edit_api_namespace_api_form_url(api_namespace_id: @api_namespace.id, id: ApiForm.last.id)
    assert_response :success
  end

  test "deny edit if not permissioned" do
    @user.update(api_accessibility: {all_namespaces: {full_read_access: 'true'}})
    sign_in(@user)

    get edit_api_namespace_api_form_url(api_namespace_id: @api_namespace.id, id: ApiForm.last.id)
    assert_response :redirect
    assert_equal "You do not have the permission to do that. Only users with full_access or full_access_for_api_form_only are allowed to perform that action.", flash[:alert]
  end

  test "should update api_form if permissioned" do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})
    sign_in(@user)

    patch api_namespace_api_form_url(@api_form, api_namespace_id: @api_form.api_namespace_id), params: { api_form: { properties: @api_form.properties } }
    assert_redirected_to api_namespace_url(@api_form.api_namespace.slug)

    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_form_only: 'true'}})
    patch api_namespace_api_form_url(@api_form, api_namespace_id: @api_form.api_namespace_id), params: { api_form: { properties: @api_form.properties } }
    assert_redirected_to api_namespace_url(@api_form.api_namespace.slug)
  end

  test "deny update api_form if not permissioned" do
    @user.update(api_accessibility: {all_namespaces: {full_read_access: 'true'}})
    sign_in(@user)

    patch api_namespace_api_form_url(@api_form, api_namespace_id: @api_form.api_namespace_id), params: { api_form: { properties: @api_form.properties } }
    assert_response :redirect
    assert_equal "You do not have the permission to do that. Only users with full_access or full_access_for_api_form_only are allowed to perform that action.", flash[:alert]
  end
end
