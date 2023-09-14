require "test_helper"

class MeetingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @meeting = meetings(:one)
    @user = users(:public)
    @user.update(can_manage_email: true)
    sign_in(@user)
  end

  test "should get index" do
    get meetings_url
    assert_response :success
  end

  test "should get new" do
    get new_meeting_url
    assert_response :success
  end

  test "should create meeting" do
    assert_difference('Meeting.count') do
      post meetings_url, params: { meeting: { description: @meeting.description, end_time: @meeting.end_time, location: @meeting.location, name: @meeting.name, participant_emails: ['contact@restarone.com'], start_time: @meeting.start_time, status: @meeting.status, timezone: @meeting.timezone } }
    end

    assert_redirected_to meeting_url(Meeting.last)
  end

  test "should show meeting" do
    get meeting_url(@meeting)
    assert_response :success
  end

  test "should get edit" do
    get edit_meeting_url(@meeting)
    assert_response :success
  end

  test "should update meeting" do
    patch meeting_url(@meeting), params: { meeting: { description: @meeting.description, end_time: @meeting.end_time, location: @meeting.location, name: @meeting.name, participant_emails: @meeting.participant_emails, start_time: @meeting.start_time, status: "TENTATIVE", timezone: @meeting.timezone } }
    assert_redirected_to meeting_url(@meeting)
  end

  test "should destroy meeting" do
    assert_difference('Meeting.count', -1) do
      delete meeting_url(@meeting)
    end

    assert_redirected_to meetings_url
  end
end
