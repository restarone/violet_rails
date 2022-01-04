require "application_system_test_case"

class ApiNamespacesTest < ApplicationSystemTestCase
  setup do
    @api_namespace = api_namespaces(:one)
  end

  test "visiting the index" do
    visit api_namespaces_url
    assert_selector "h1", text: "Api Namespaces"
  end

  test "creating a Api namespace" do
    visit api_namespaces_url
    click_on "New Api Namespace"

    fill_in "Name", with: @api_namespace.name
    fill_in "Namespace type", with: @api_namespace.namespace_type
    fill_in "Properties", with: @api_namespace.properties
    check "Requires authentication" if @api_namespace.requires_authentication
    fill_in "Version", with: @api_namespace.version
    click_on "Create Api namespace"

    assert_text "Api namespace was successfully created"
    click_on "Back"
  end

  test "updating a Api namespace" do
    visit api_namespaces_url
    click_on "Edit", match: :first

    fill_in "Name", with: @api_namespace.name
    fill_in "Namespace type", with: @api_namespace.namespace_type
    fill_in "Properties", with: @api_namespace.properties
    check "Requires authentication" if @api_namespace.requires_authentication
    fill_in "Version", with: @api_namespace.version
    click_on "Update Api namespace"

    assert_text "Api namespace was successfully updated"
    click_on "Back"
  end

  test "destroying a Api namespace" do
    visit api_namespaces_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Api namespace was successfully destroyed"
  end
end
