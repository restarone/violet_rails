require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @subdomain = subdomains(:public)
    @user.update(can_manage_web: true)
  end

  test "should deny #dashboard if not signed in" do
    get dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "should deny #dashboard if not permissioned" do
    sign_in(@user)
    @user.update(can_manage_web: false)
    get dashboard_url
    assert_response :redirect
  end

  test "should get #dashboard if signed in and permissioned" do
    sign_in(@user)
    get dashboard_url
    assert_response :success
  end

  test "should deny #visit if not permissioned" do
    @subdomain.update!(tracking_enabled: true)
    get root_url
    sign_in(@user)
    @user.update(can_manage_web: false)
    get dashboard_visits_url(ahoy_visit_id: Ahoy::Visit.first.id)
    assert_response :redirect
  end

  test "should get #visit if signed in and permissioned" do
    @subdomain.update!(tracking_enabled: true)
    get root_url
    sign_in(@user)
    get dashboard_visits_url(ahoy_visit_id: Ahoy::Visit.first.id)
    assert_response :success
  end

  test "should deny #events_detail if not permissioned" do
    @subdomain.update!(tracking_enabled: true)
    get root_url
    sign_in(@user)
    @user.update(can_manage_web: false)
    Ahoy::Visit.first.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)
    get dashboard_events_url(ahoy_event_type: 'test')
    assert_response :redirect
  end

  test "should get #events_detail if signed in and permissioned" do
    @subdomain.update!(tracking_enabled: true)
    get root_url
    sign_in(@user)
    Ahoy::Visit.first.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)
    get dashboard_events_url(ahoy_event_type: 'test')
    assert_response :success
  end

  test "should deny #events_list if not permissioned" do
    @subdomain.update!(tracking_enabled: true)
    get root_url
    sign_in(@user)
    @user.update(can_manage_web: false)
    get dashboard_events_list_url
    assert_response :redirect
  end

  test "should get #events_list if signed in and permissioned" do
    @subdomain.update!(tracking_enabled: true)
    get root_url
    sign_in(@user)
    get dashboard_events_list_url
    assert_response :success
  end
end
