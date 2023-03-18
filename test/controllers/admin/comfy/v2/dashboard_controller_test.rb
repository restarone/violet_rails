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

    # Page Visit Events
    page_visit_data = assigns(:page_visit_events)
    assert_equal page_visit_data[:events_count], 1
    assert_equal page_visit_data[:previous_period_events_count], 1
    assert_equal page_visit_data[:pie_chart_data]['Single time visitor'], 1
    assert_equal page_visit_data[:pie_chart_data]['Recurring visitors'], 0

    # Click Events
    click_event_data = assigns(:click_events)
    assert_equal click_event_data[:events_count], 1
    assert_equal click_event_data[:previous_period_events_count], 1
    assert click_event_data[:label_grouped_events].keys.include?(click_event_1.label)
    assert click_event_data[:previous_label_grouped_events].keys.include?(click_event_2.label)

    # Video View Events
    video_view_event_data = assigns(:video_view_events)
    assert_equal video_view_event_data[:events_count], 1
    assert_equal video_view_event_data[:previous_period_events_count], 1
    assert_equal video_view_event_data[:watch_time], Ahoy::Event.where(id: video_watch_event_1_page_2.id).total_watch_time_for_video_events
    assert_equal video_view_event_data[:previous_watch_time], Ahoy::Event.where(id: video_watch_event_1.id).total_watch_time_for_video_events
    assert_equal video_view_event_data[:avg_view_duration], Ahoy::Event.where(id: video_watch_event_1_page_2.id).avg_view_duration_for_video_events
    assert_equal video_view_event_data[:previous_avg_view_duration], Ahoy::Event.where(id: video_watch_event_1.id).avg_view_duration_for_video_events
    assert_equal video_view_event_data[:avg_view_percent], Ahoy::Event.where(id: video_watch_event_1_page_2.id).avg_view_percentage_for_video_events
    assert_equal video_view_event_data[:previous_avg_view_percent], Ahoy::Event.where(id: video_watch_event_1.id).avg_view_percentage_for_video_events

    # When range params is present
    get v2_dashboard_url, params: {start_date: (Time.now.beginning_of_month - 2.months).strftime('%Y-%m-%d'), end_date: Time.now.end_of_month.strftime('%Y-%m-%d'), interval: "3 months" }

    assert_equal (Time.now.beginning_of_month - 2.months).to_date, assigns(:start_date)
    assert_equal Time.now.end_of_month.to_date, assigns(:end_date)
  
    # Page Visit Events
    page_visit_data = assigns(:page_visit_events)
    assert_equal page_visit_data[:events_count], 2
    assert_equal page_visit_data[:previous_period_events_count], 1
    assert_equal page_visit_data[:pie_chart_data]['Single time visitor'], 0
    assert_equal page_visit_data[:pie_chart_data]['Recurring visitors'], 1

    # Click Events
    click_event_data = assigns(:click_events)
    assert_equal click_event_data[:events_count], 2
    assert_equal click_event_data[:previous_period_events_count], 1
    assert click_event_data[:label_grouped_events].keys.include?(click_event_1.label)
    assert_equal click_event_data[:label_grouped_events][click_event_1.label], 2
    assert click_event_data[:previous_label_grouped_events].keys.include?(click_event_2.label)
    assert_equal click_event_data[:previous_label_grouped_events][click_event_2.label], 1

    # Video View Events
    video_view_event_data = assigns(:video_view_events)
    assert_equal video_view_event_data[:events_count], 2
    assert_equal video_view_event_data[:previous_period_events_count], 1
    assert_equal video_view_event_data[:watch_time], Ahoy::Event.where(id: [video_watch_event_1.id, video_watch_event_1_page_2.id]).total_watch_time_for_video_events
    assert_equal video_view_event_data[:previous_watch_time], Ahoy::Event.where(id: video_watch_event_2.id).total_watch_time_for_video_events
    assert_equal video_view_event_data[:avg_view_duration], Ahoy::Event.where(id: [video_watch_event_1.id, video_watch_event_1_page_2.id]).avg_view_duration_for_video_events
    assert_equal video_view_event_data[:previous_avg_view_duration], Ahoy::Event.where(id: video_watch_event_2.id).avg_view_duration_for_video_events
    assert_equal video_view_event_data[:avg_view_percent], Ahoy::Event.where(id: [video_watch_event_1.id, video_watch_event_1_page_2.id]).avg_view_percentage_for_video_events
    assert_equal video_view_event_data[:previous_avg_view_percent], Ahoy::Event.where(id: video_watch_event_2.id).avg_view_percentage_for_video_events

    # When page params present, it should filter by page
    get v2_dashboard_url, params: {start_date: (Time.now.beginning_of_month - 2.months).strftime('%Y-%m-%d'), end_date: Time.now.end_of_month.strftime('%Y-%m-%d'), interval: "3 months", page: @page.id }

    # Page Visit Events
    page_visit_data = assigns(:page_visit_events)
    assert_equal page_visit_data[:events_count], 1
    assert_equal page_visit_data[:previous_period_events_count], 0
    assert_equal page_visit_data[:pie_chart_data]['Single time visitor'], 1
    assert_equal page_visit_data[:pie_chart_data]['Recurring visitors'], 0

    # Click Events
    click_event_data = assigns(:click_events)
    assert_equal click_event_data[:events_count], 1
    assert_equal click_event_data[:previous_period_events_count], 1
    assert click_event_data[:label_grouped_events].keys.include?(click_event_1.label)
    assert_equal click_event_data[:label_grouped_events][click_event_1.label], 1
    assert click_event_data[:previous_label_grouped_events].keys.include?(click_event_2.label)
    assert_equal click_event_data[:previous_label_grouped_events][click_event_2.label], 1

    # Video View Events
    video_view_event_data = assigns(:video_view_events)
    assert_equal video_view_event_data[:events_count], 1
    assert_equal video_view_event_data[:previous_period_events_count], 1
    assert_equal video_view_event_data[:watch_time], Ahoy::Event.where(id: video_watch_event_1.id).total_watch_time_for_video_events
    assert_equal video_view_event_data[:previous_watch_time], Ahoy::Event.where(id: video_watch_event_2.id).total_watch_time_for_video_events
    assert_equal video_view_event_data[:avg_view_duration], Ahoy::Event.where(id: video_watch_event_1.id).avg_view_duration_for_video_events
    assert_equal video_view_event_data[:previous_avg_view_duration], Ahoy::Event.where(id: video_watch_event_2.id).avg_view_duration_for_video_events
    assert_equal video_view_event_data[:avg_view_percent], Ahoy::Event.where(id: video_watch_event_1.id).avg_view_percentage_for_video_events
    assert_equal video_view_event_data[:previous_avg_view_percent], Ahoy::Event.where(id: video_watch_event_2.id).avg_view_percentage_for_video_events
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

  test "#dashboard: should not throw error if a video detail is missing in the ahoy_events" do
    @subdomain.update!(tracking_enabled: true)
    visit = Ahoy::Visit.first

    video_watch_event_1 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days),  properties: {"label"=>"watched_this_video", "page_id"=>@page.id, "category"=>"video_view", "resource_id"=>@api_resource.id, "video_start"=>true, "total_duration"=>11944.444}) 
    video_watch_event_2 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days),  properties: {"label"=>"watched_this_video", "page_id"=>@page.id, "category"=>"video_view", "watch_time"=>11891, "video_start"=>true, "total_duration"=>11944.444}) 
    video_watch_event_3 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days),  properties: {"label"=>"watched_this_video", "page_id"=>@page.id, "category"=>"video_view", "watch_time"=>11891, "resource_id"=>@api_resource.id, "total_duration"=>11944.444}) 
    video_watch_event_4 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: (Time.now.beginning_of_month - 4.days),  properties: {"label"=>"watched_this_video", "page_id"=>@page.id, "category"=>"video_view", "watch_time"=>11891, "resource_id"=>@api_resource.id, "video_start"=>true}) 

    video_watch_event_1_page_2 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: Time.now,  properties: {"label"=>"watched_this_video", "page_id"=>@page_2.id, "category"=>"video_view", "resource_id"=>@api_resource.id, "video_start"=>true, "total_duration"=>11944.444})    
    video_watch_event_2_page_2 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: Time.now,  properties: {"label"=>"watched_this_video", "page_id"=>@page_2.id, "category"=>"video_view", "watch_time"=>11891, "video_start"=>true, "total_duration"=>11944.444})    
    video_watch_event_3_page_2 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: Time.now,  properties: {"label"=>"watched_this_video", "page_id"=>@page_2.id, "category"=>"video_view", "watch_time"=>11891, "resource_id"=>@api_resource.id, "total_duration"=>11944.444})    
    video_watch_event_4_page_2 = visit.events.create(name: 'test-video-watched', user_id: @user.id, time: Time.now,  properties: {"label"=>"watched_this_video", "page_id"=>@page_2.id, "category"=>"video_view", "watch_time"=>11891, "resource_id"=>@api_resource.id, "video_start"=>true})    

    @user.update(can_manage_analytics: true)
    sign_in(@user)  

    assert_nothing_raised do
      get v2_dashboard_url
    end

    assert_response :success
  end
end
