require "test_helper"

class Comfy::Admin::V2::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @subdomain = subdomains(:public)
    @user.update(can_manage_analytics: true)
    @page = comfy_cms_pages(:root)
    site = Comfy::Cms::Site.first
    layout = site.layouts.last
    @page_2 = layout.pages.create(
      site_id: site.id,
      label: 'test-cms-page',
      slug: 'test-cms-page',
    )
    @api_resource = api_resources(:one)
  end

  test "should deny #v2_dashboard if not signed in" do
    get v2_dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "should deny #v2_dashboard if not permissioned" do
    sign_in(@user)
    @user.update(can_manage_analytics: false)
    get v2_dashboard_url
    assert_response :redirect
  end

  test "should get #v2_dashboard if signed in and permissioned" do
    sign_in(@user)
    get v2_dashboard_url
    assert_response :success
  end

  test "should render view even if video isn't properly loaded" do
    @subdomain.update!(tracking_enabled: true)
    visit = Ahoy::Visit.first
    page_visit_event_1 = visit.events.create(name: 'comfy-cms-page-visit', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days),  properties: {"label"=>"test_page_view", "page_id"=>@page.id, "category"=>"page_visit", "page_title"=>"lvh.me:5250"})
    click_event_1 = visit.events.create(name: 'test-link-click', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days), properties: {"tag"=>"BUTTON", "label"=>"test link", "page_id"=>@page.id, "category"=>"click"})
    video_watch_event_1 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days),  properties: {"label"=>"watched_this_video", "page_id"=>@page.id, "category"=>"video_view", "watch_time"=>11891, "resource_id"=>@api_resource.id, "video_start"=>true, "total_duration"=>nil}) 

    visit_1 = visit.dup
    visit_1.save!

    @user.update(can_manage_analytics: true)
    sign_in(@user)

    get v2_dashboard_url
    assert_response :success
  end

  test "#dashboard: should set correct data" do
    @subdomain.update!(tracking_enabled: true)
    visit = Ahoy::Visit.first
    page_visit_event_1 = visit.events.create(name: 'comfy-cms-page-visit', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days),  properties: {"label"=>"test_page_view", "page_id"=>@page.id, "category"=>"page_visit", "page_title"=>"lvh.me:5250"})
    click_event_1 = visit.events.create(name: 'test-link-click', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days), properties: {"tag"=>"BUTTON", "label"=>"test link", "page_id"=>@page.id, "category"=>"click"})
    video_watch_event_1 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days),  properties: {"label"=>"watched_this_video", "page_id"=>@page.id, "category"=>"video_view", "watch_time"=>11891, "resource_id"=>@api_resource.id, "video_start"=>true, "total_duration"=>11944.444}) 

    page_visit_event_1_page_2 = visit.events.create(name: 'comfy-cms-page-visit', user_id: @user.id, time: Time.now,  properties: {"label"=>"test_page_view", "page_id"=>@page_2.id, "category"=>"page_visit", "page_title"=>"lvh.me:5250"})
    click_event_1_page_2 = visit.events.create(name: 'test-link-click', user_id: @user.id, time: Time.now, properties: {"tag"=>"BUTTON", "label"=>"test link", "page_id"=>@page_2.id, "category"=>"click"})
    video_watch_event_1_page_2 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: Time.now,  properties: {"label"=>"watched_this_video", "page_id"=>@page_2.id, "category"=>"video_view", "watch_time"=>11891, "resource_id"=>@api_resource.id, "video_start"=>true, "total_duration"=>11944.444})    

    visit_1 = visit.dup
    visit_1.save!
    page_visit_event_2 = visit.events.create(name: 'comfy-cms-page-visit', user_id: @user.id, time: (Time.now.beginning_of_month - 4.months),  properties: {"label"=>"test_page_view", "page_id"=>@page_2.id, "category"=>"page_visit", "page_title"=>"lvh.me:5250"})
    click_event_2 = visit.events.create(name: 'test-link-click', user_id: @user.id, time: (Time.now.beginning_of_month - 4.months), properties: {"tag"=>"BUTTON", "label"=>"test link", "page_id"=>@page.id, "category"=>"click"})
    video_watch_event_2 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: (Time.now.beginning_of_month - 4.months),  properties: {"label"=>"watched_this_video", "page_id"=>@page.id, "category"=>"video_view", "watch_time"=>11891, "resource_id"=>2, "video_start"=>true, "total_duration"=>11944.444}) 

    @user.update(can_manage_analytics: true)
    sign_in(@user)  

    get v2_dashboard_url

    # default range should be current month and previous period should be last month
    assert_equal Date.today.beginning_of_month, assigns(:start_date)
    assert_equal Date.today.end_of_month, assigns(:end_date)

    assert_equal [page_visit_event_1_page_2.id], assigns(:page_visit_events).pluck(:id)
    assert_equal [click_event_1_page_2.id], assigns(:click_events).pluck(:id)
    assert_equal [video_watch_event_1_page_2.id], assigns(:video_view_events).pluck(:id)

    assert_equal [page_visit_event_1.id], assigns(:previous_period_page_visit_events).pluck(:id)
    assert_equal [click_event_1.id], assigns(:previous_period_click_events).pluck(:id)
    assert_equal [video_watch_event_1.id], assigns(:previous_period_video_view_events).pluck(:id)

    # When range params is present
    get v2_dashboard_url, params: {start_date: (Time.now.beginning_of_month - 2.months).strftime('%Y-%m-%d'), end_date: Time.now.end_of_month.strftime('%Y-%m-%d'), interval: "3 months" }

    assert_equal (Time.now.beginning_of_month - 2.months).to_date, assigns(:start_date)
    assert_equal Time.now.end_of_month.to_date, assigns(:end_date)
  
    assert_equal [page_visit_event_1.id, page_visit_event_1_page_2.id].sort, assigns(:page_visit_events).pluck(:id).sort
    assert_equal [click_event_1.id, click_event_1_page_2.id].sort, assigns(:click_events).pluck(:id).sort
    assert_equal [video_watch_event_1.id, video_watch_event_1_page_2.id].sort, assigns(:video_view_events).pluck(:id).sort

    assert_equal [page_visit_event_2.id], assigns(:previous_period_page_visit_events).pluck(:id)
    assert_equal [click_event_2.id], assigns(:previous_period_click_events).pluck(:id)
    assert_equal [video_watch_event_2.id], assigns(:previous_period_video_view_events).pluck(:id)

    # When page params present, it should filter by page
    get v2_dashboard_url, params: {start_date: (Time.now.beginning_of_month - 2.months).strftime('%Y-%m-%d'), end_date: Time.now.end_of_month.strftime('%Y-%m-%d'), interval: "3 months", page: @page.id }
  
    assert_equal [page_visit_event_1.id], assigns(:page_visit_events).pluck(:id)
    assert_equal [click_event_1.id], assigns(:click_events).pluck(:id)
    assert_equal [video_watch_event_1.id], assigns(:video_view_events).pluck(:id)

    assert_empty assigns(:previous_period_page_visit_events)
    assert_equal [click_event_2.id], assigns(:previous_period_click_events).pluck(:id)
    assert_equal [video_watch_event_2.id], assigns(:previous_period_video_view_events).pluck(:id)
  end

  test "#dashboard: should show pie-chart data and last time-period comparision correctly" do
    @subdomain.update!(tracking_enabled: true)
    
    recurring_visit = Ahoy::Visit.first
    recurring_visit.update!(visit_token: 'visit_token_1', visitor_token: 'visitor_token_1')

    single_time_visit_1 = recurring_visit.dup
    single_time_visit_1.update!(visit_token: 'visit_token_2', visitor_token: 'visitor_token_2')

    single_time_visit_2 = recurring_visit.dup
    single_time_visit_2.update!(visit_token: 'visit_token_3', visitor_token: 'visitor_token_3')

    recurring_current_page_visit_events_page_2 = (1..3).each do
      recurring_visit.events.create(name: 'comfy-cms-page-visit', user_id: @user.id, time: Time.now,  properties: {"label"=>"test_page_view", "page_id"=>@page_2.id, "category"=>"page_visit", "page_title"=>"lvh.me:5250"})
    end

    single_time_current_page_visit_events_page_2 = [single_time_visit_1, single_time_visit_2].each do |visit|
      visit.events.create(name: 'comfy-cms-page-visit', user_id: @user.id, time: Time.now,  properties: {"label"=>"test_page_view", "page_id"=>@page_2.id, "category"=>"page_visit", "page_title"=>"lvh.me:5250"})
    end

    recurring_visit.events.create(name: 'comfy-cms-page-visit', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days),  properties: {"label"=>"test_page_view", "page_id"=>@page.id, "category"=>"page_visit", "page_title"=>"lvh.me:5250"})
    single_time_previous_page_visit_events_page_1 = [single_time_visit_1, single_time_visit_2].each do |visit|
      visit.events.create(name: 'comfy-cms-page-visit', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days),  properties: {"label"=>"test_page_view", "page_id"=>@page.id, "category"=>"page_visit", "page_title"=>"lvh.me:5250"})
    end

    @user.update(can_manage_analytics: true)
    sign_in(@user)  

    get v2_dashboard_url

    # default range should be current month and previous period should be last month
    assert_equal Date.today.beginning_of_month, assigns(:start_date)
    assert_equal Date.today.end_of_month, assigns(:end_date)

    assert_select ".vr-analytics-page-visit-events-donut-chart script", { count: 1, text: /\"Single time visitor\",2\],\[\"Recurring visitors\",1/ }
    assert_select ".vr-analytics-section-header .vr-analytics-percent-change .positive", { count: 1, text: /66.67 %/}
  end
end
