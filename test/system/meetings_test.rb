require "application_system_test_case"

class MeetingsTest < ApplicationSystemTestCase
  setup do
    @meeting = meetings(:one)
  end

  test "visiting the index" do
    visit meetings_url
    assert_selector "h1", text: "Meetings"
  end

  test "creating a Meeting" do
    visit meetings_url
    click_on "New Meeting"

    fill_in "Description", with: @meeting.description
    fill_in "End time", with: @meeting.end_time
    fill_in "External meeting", with: @meeting.external_meeting_id
    fill_in "Location", with: @meeting.location
    fill_in "Name", with: @meeting.name
    fill_in "Participant emails", with: @meeting.participant_emails
    fill_in "Start time", with: @meeting.start_time
    fill_in "Status", with: @meeting.status
    fill_in "Timezone", with: @meeting.timezone
    click_on "Create Meeting"

    assert_text "Meeting was successfully created"
    click_on "Back"
  end

  test "updating a Meeting" do
    visit meetings_url
    click_on "Edit", match: :first

    fill_in "Description", with: @meeting.description
    fill_in "End time", with: @meeting.end_time
    fill_in "External meeting", with: @meeting.external_meeting_id
    fill_in "Location", with: @meeting.location
    fill_in "Name", with: @meeting.name
    fill_in "Participant emails", with: @meeting.participant_emails
    fill_in "Start time", with: @meeting.start_time
    fill_in "Status", with: @meeting.status
    fill_in "Timezone", with: @meeting.timezone
    click_on "Update Meeting"

    assert_text "Meeting was successfully updated"
    click_on "Back"
  end

  test "destroying a Meeting" do
    visit meetings_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Meeting was successfully destroyed"
  end
end
