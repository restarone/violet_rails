require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @subdomain = subdomains(:public)
    @user.update(can_manage_analytics: true)
  end

  test "should deny #dashboard if not signed in" do
    get dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "should deny #dashboard if not permissioned" do
    sign_in(@user)
    @user.update(can_manage_analytics: false)
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
    @user.update(can_manage_analytics: false)
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
    @user.update(can_manage_analytics: false)
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
    @user.update(can_manage_analytics: false)
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

  test "should deny #destroy_event if not permissioned" do
    @subdomain.update!(tracking_enabled: true)
    event = Ahoy::Visit.first.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)

    @user.update(can_manage_analytics: false)
    sign_in(@user)

    delete dashboard_destroy_event_url(ahoy_event_type: event.name)

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users who can_manage_analytics are allowed to perform that action."
    assert_equal expected_message, request.flash[:alert]
  end

  test "should sucessfully #destroy_event if signed in and permissioned" do
    @subdomain.update!(tracking_enabled: true)
    event = Ahoy::Visit.first.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)

    @user.update(can_manage_analytics: true)
    sign_in(@user)

    delete dashboard_destroy_event_url(ahoy_event_type: event.name)

    assert_response :redirect

    expected_message = "All test events and its associated visits has been deleted successfully."
    assert_equal expected_message, request.flash[:notice]
  end

  test "#destroy_event should give error if system-event is provided" do
    @subdomain.update!(tracking_enabled: true)
    event = Ahoy::Visit.first.events.create(name: Ahoy::Event::SYSTEM_EVENTS.keys.first, user_id: @user.id, time: Time.zone.now)

    @user.update(can_manage_analytics: true)
    sign_in(@user)

    delete dashboard_destroy_event_url(ahoy_event_type: event.name)

    assert_response :redirect

    expected_message = "System defined events and their visits cannot be deleted."
    assert_match expected_message, request.flash[:alert]
  end

  test "#destroy_event should delete only the specified event-type and its associated visits" do
    @subdomain.update!(tracking_enabled: true)
    visit = Ahoy::Visit.first
    event = visit.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)

    visit_1 = visit.dup
    visit_1.save!
    event_1 = visit_1.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)

    visit_2 = visit.dup
    visit_2.save!
    event_2 = visit_2.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)

    visit_3 = visit.dup
    visit_3.save!
    event_3 = visit_3.events.create(name: 'test-2', user_id: @user.id, time: Time.zone.now)

    @user.update(can_manage_analytics: true)
    sign_in(@user)

    delete dashboard_destroy_event_url(ahoy_event_type: event.name)

    assert_response :redirect

    expected_message = "All test events and its associated visits has been deleted successfully."
    assert_equal expected_message, request.flash[:notice]

    # Specified Events and Associated Visits are only deleted
    assert_equal 0, Ahoy::Event.where(name: 'test').size
    assert_equal 0, Ahoy::Visit.where(id: [visit.id, visit_1.id, visit_2.id]).size

    # Other are untouched
    assert_equal 1, Ahoy::Event.where(name: event_3.name).size
    assert_equal 1, Ahoy::Visit.where(id: [visit_3.id]).size
  end

  test "should deny #dashboard_destroy_visits if not permissioned" do
    @subdomain.update!(tracking_enabled: true)
    event = Ahoy::Visit.first.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)

    @user.update(can_manage_analytics: false)
    sign_in(@user)

    delete dashboard_destroy_visits_url(ahoy_event_type: event.name)

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users who can_manage_analytics are allowed to perform that action."
    assert_equal expected_message, request.flash[:alert]
  end

  test "should sucessfully #dashboard_destroy_visits if signed in and permissioned" do
    @subdomain.update!(tracking_enabled: true)
    event = Ahoy::Visit.first.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)

    @user.update(can_manage_analytics: true)
    sign_in(@user)

    delete dashboard_destroy_visits_url(ahoy_event_type: event.name)

    assert_response :redirect

    expected_message = "All associated visits of test events has been deleted successfully."
    assert_equal expected_message, request.flash[:notice]
  end


  test "#dashboard_destroy_visits should give error if system-event is provided" do
    @subdomain.update!(tracking_enabled: true)
    event = Ahoy::Visit.first.events.create(name: Ahoy::Event::SYSTEM_EVENTS.keys.first, user_id: @user.id, time: Time.zone.now)

    @user.update(can_manage_analytics: true)
    sign_in(@user)

    delete dashboard_destroy_visits_url(ahoy_event_type: event.name)

    assert_response :redirect

    expected_message = "System defined events and their visits cannot be deleted."
    assert_match expected_message, request.flash[:alert]
  end

  test "#dashboard_destroy_visits should delete only the specified event-type and its associated visits" do
    @subdomain.update!(tracking_enabled: true)
    visit = Ahoy::Visit.first
    event = visit.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)

    visit_1 = visit.dup
    visit_1.save!
    event_1 = visit_1.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)

    visit_2 = visit.dup
    visit_2.save!
    event_2 = visit_2.events.create(name: 'test', user_id: @user.id, time: Time.zone.now)

    visit_3 = visit.dup
    visit_3.save!
    event_3 = visit_3.events.create(name: 'test-2', user_id: @user.id, time: Time.zone.now)

    @user.update(can_manage_analytics: true)
    sign_in(@user)

    delete dashboard_destroy_visits_url(ahoy_event_type: event.name)

    assert_response :redirect

    expected_message = "All associated visits of test events has been deleted successfully."
    assert_equal expected_message, request.flash[:notice]

    # Associated Visits are only deleted
    assert_equal 3, Ahoy::Event.where(name: 'test').size
    assert_equal 0, Ahoy::Visit.where(id: [visit.id, visit_1.id, visit_2.id]).size
    
    # Other are untouched
    assert_equal 1, Ahoy::Event.where(name: event_3.name).size
    assert_equal 1, Ahoy::Visit.where(id: [visit_3.id]).size
  end
end
