require "application_system_test_case"

class ApiClientsTest < ApplicationSystemTestCase
  setup do
    @api_client = api_clients(:one)
  end

  test "visiting the index" do
    visit api_clients_url
    assert_selector "h1", text: "Api Clients"
  end

  test "creating a Api client" do
    visit api_clients_url
    click_on "New Api Client"

    fill_in "Api namespace", with: @api_client.api_namespace_id
    fill_in "Authentication strategy", with: @api_client.authentication_strategy
    fill_in "Bearer token", with: @api_client.bearer_token
    fill_in "Label", with: @api_client.label
    click_on "Create Api client"

    assert_text "Api client was successfully created"
    click_on "Back"
  end

  test "updating a Api client" do
    visit api_clients_url
    click_on "Edit", match: :first

    fill_in "Api namespace", with: @api_client.api_namespace_id
    fill_in "Authentication strategy", with: @api_client.authentication_strategy
    fill_in "Bearer token", with: @api_client.bearer_token
    fill_in "Label", with: @api_client.label
    click_on "Update Api client"

    assert_text "Api client was successfully updated"
    click_on "Back"
  end

  test "destroying a Api client" do
    visit api_clients_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Api client was successfully destroyed"
  end
end
