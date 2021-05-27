require "application_system_test_case"

class CallToActionsTest < ApplicationSystemTestCase
  setup do
    @call_to_action = call_to_actions(:one)
  end

  test "visiting the index" do
    visit call_to_actions_url
    assert_selector "h1", text: "Call To Actions"
  end

  test "creating a Call to action" do
    visit call_to_actions_url
    click_on "New Call To Action"

    fill_in "Cta type", with: @call_to_action.cta_type
    fill_in "Title", with: @call_to_action.title
    click_on "Create Call to action"

    assert_text "Call to action was successfully created"
    click_on "Back"
  end

  test "updating a Call to action" do
    visit call_to_actions_url
    click_on "Edit", match: :first

    fill_in "Cta type", with: @call_to_action.cta_type
    fill_in "Title", with: @call_to_action.title
    click_on "Update Call to action"

    assert_text "Call to action was successfully updated"
    click_on "Back"
  end

  test "destroying a Call to action" do
    visit call_to_actions_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Call to action was successfully destroyed"
  end
end
