require "application_system_test_case"

class ApiResourcesTest < ApplicationSystemTestCase
  setup do
    @api_resource = api_resources(:one)
  end

  test "visiting the index" do
    visit api_resources_url
    assert_selector "h1", text: "Api Resources"
  end

  test "creating a Api resource" do
    visit api_resources_url
    click_on "New Api Resource"

    fill_in "Api namespace", with: @api_resource.api_namespace_id
    fill_in "Properties", with: @api_resource.properties
    click_on "Create Api resource"

    assert_text "Api resource was successfully created"
    click_on "Back"
  end

  test "updating a Api resource" do
    visit api_resources_url
    click_on "Edit", match: :first

    fill_in "Api namespace", with: @api_resource.api_namespace_id
    fill_in "Properties", with: @api_resource.properties
    click_on "Update Api resource"

    assert_text "Api resource was successfully updated"
    click_on "Back"
  end

  test "destroying a Api resource" do
    visit api_resources_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Api resource was successfully destroyed"
  end
end
