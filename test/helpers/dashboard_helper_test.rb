require 'test_helper'

class DashboardHelperTest < ActionView::TestCase
  test 'redacts devise user links' do
    url = "http://violet.lvh.me:5250/users/confirmation?confirmation_token=fQg7D1kv1d_12f8U_yDX"
    url_2 = "http://violet.lvh.me:5250/users/confirmation?confirmation_token=fQg7D1kv1d_12f8U_yDX"
    url_3 = "https://violet.restarone.solutions/users/password/edit?reset_password_token=-Es6rYgrrDssyyzVNnA6"
    url_non_redactable = "http://violet.lvh.me:5250/users/golf"
    assert_equal "private-system-url-redacted" , redact_private_urls(url)
    assert_equal "private-system-url-redacted" , redact_private_urls(url_2)
    assert_equal "private-system-url-redacted" , redact_private_urls(url_3)
    assert_equal url_non_redactable , redact_private_urls(url_non_redactable)
  end

  test 'page_visit_chart_data' do
    travel_to Date.new(2023, 01, 26) do
      visit = Ahoy::Visit.first
      visit.update!(device_type: 'Desktop')
      visit.events.create(name: 'test-page-view', user_id: 1, time: Time.now,  properties: {
        label: "test_page_view",
        page_id: 1,
        category: "page_visit",
      }) 

      visit.events.create(name: 'test-page-view', user_id: 1, time: 1.day.ago,  properties: {
        label: "test_page_view",
        page_id: 1,
        category: "page_visit",
      }) 

      visit.events.create(name: 'test-page-view', user_id: 1, time: 2.months.ago,  properties: {
        label: "test_page_view",
        page_id: 1,
        category: "page_visit",
      }) 

      visit.events.create(name: 'test-page-view', user_id: 1, time: 6.months.ago,  properties: {
        label: "test_page_view",
        page_id: 1,
        category: "page_visit",
      }) 

      visit.events.create(name: 'test-page-view', user_id: 1, time: 2.years.ago,  properties: {
        label: "test_page_view",
        page_id: 1,
        category: "page_visit",
      })
      
      # should split into days
      assert_equal [{:name=>"Desktop", :data=>{"#{2.days.ago.strftime('%-d %^b %Y')}"=>0, "#{1.days.ago.strftime('%-d %^b %Y')}"=>1, "#{Time.now.strftime('%-d %^b %Y')}"=>1}}], page_visit_chart_data(Ahoy::Event.where(name: 'test-page-view').joins(:visit), 2.days.ago.to_date, Time.now.to_date)

      # should split into weeks
      assert_equal [{:name=>"Desktop", :data=>{"#{4.weeks.ago.strftime('%V')}"=>0, "#{3.weeks.ago.strftime('%V')}"=>0, "#{2.weeks.ago.strftime('%V')}"=>0, "#{1.weeks.ago.strftime('%V')}"=>2, "#{Time.now.strftime('%V')}"=>0}}], page_visit_chart_data(Ahoy::Event.where(name: 'test-page-view').joins(:visit), Time.now.beginning_of_month.to_date, Time.now.end_of_month.to_date)

      # should split into months
      assert_equal [{:name=>"Desktop", :data=>{"#{2.months.ago.strftime('%^b %Y')}"=>1, "#{1.months.ago.strftime('%^b %Y')}"=>0, "#{Time.now.strftime('%^b %Y')}"=>2}}], page_visit_chart_data(Ahoy::Event.where(name: 'test-page-view').joins(:visit), 2.months.ago.to_date, Time.now.to_date)

      # should split into years
      assert_equal [{:name=>"Desktop", :data=>{"#{2.years.ago.strftime('%Y')}"=>1, "#{1.years.ago.strftime('%Y')}"=>2, "#{Time.now.strftime('%Y')}"=>2}}], page_visit_chart_data(Ahoy::Event.where(name: 'test-page-view').joins(:visit), 2.years.ago.to_date, Time.now.to_date)
    end
  end

  test 'page_name' do
    assert_equal 'Website', page_name(nil)

    page = comfy_cms_pages(:root)
    assert_equal page.label, page_name(page.id)
  end

  test 'display_percent_change' do
    refute display_percent_change(100, 0)

    assert_equal "<div class=\"positive\"><i class=\"pr-2 fa fa-caret-up\"></i>20.0 %</div>", display_percent_change(60, 50)

    assert_equal "<div class=\"negative\"><i class=\"pr-2 fa fa-caret-down\"></i>16.67 %</div>", display_percent_change(50, 60)
  end

  test 'tooltip_content' do
    assert_equal "There's no data from the previous 3 months to compare", tooltip_content(1, 0, '3 months', (Time.now.beginning_of_month - 2.months).to_date, Time.now.end_of_month.to_date)

    assert_equal "This is a 100.0 % increase compared to the previous 6 months", tooltip_content(2, 1, '6 months', (Time.now.beginning_of_month - 5.months).to_date, Time.now.end_of_month.to_date)

    assert_equal "There's no data from the previous month to compare", tooltip_content(1, 0, Date.current.strftime('%B %Y'), Time.now.beginning_of_month.to_date, Time.now.end_of_month.to_date)

    assert_equal "This is a 50.0 % decrease compared to the previous month", tooltip_content(1, 2, Date.current.strftime('%B %Y'), Time.now.beginning_of_month.to_date, Time.now.end_of_month.to_date)

    assert_equal "There's no data from the previous 10 days to compare", tooltip_content(1, 0, 'Custom Interval', (Time.now - 10.days).to_date, Time.now.to_date)

    assert_equal "This is a 100.0 % increase compared to the previous 10 days", tooltip_content(2, 1, 'Custom Range', (Time.now - 10.days).to_date, Time.now.to_date)
  end

  test 'total watch time' do
    mock_video_view_events
    assert_equal 30000, total_watch_time([@video_watch_event_1, @video_watch_event_2])
  end

  test 'to_minutes' do
    assert_equal '10,000.0 min', to_minutes(10000*1000*60)
  end

  test 'total_views' do
    mock_video_view_events
    assert_equal 2, total_views([@video_watch_event_1, @video_watch_event_2, @video_watch_event_3])
  end

  test 'avg_view_duration' do
    assert_equal 0, avg_view_duration([])
    mock_video_view_events
    assert_equal 25000.0, avg_view_duration([@video_watch_event_1, @video_watch_event_2, @video_watch_event_3])
  end

  test 'avg_view_percentange' do
    mock_video_view_events
    assert_equal 50.0, avg_view_percentage([@video_watch_event_1, @video_watch_event_2, @video_watch_event_3])
  end

  private 
  
  def mock_video_view_events
    api_resource = api_resources(:one)
    api_resource_2 = api_resources(:two)
    visit = Ahoy::Visit.first
    @video_watch_event_1 = visit.events.create(name: 'test-video-watched', user_id: 1, time: Time.now,  properties: {
      label: "watched_this_video",
      page_id: 1,
      category: "video_view",
      watch_time: 10000,
      resource_id: api_resource.id,
      video_start: true,
      total_duration: 40000
    }) 

    @video_watch_event_2 = visit.events.create(name: 'test-video-watched', user_id: 1, time: Time.now,  properties: {
      label: "watched_this_video",
      category: "video_view",
      page_id: 1,
      watch_time: 20000,
      resource_id: api_resource_2.id,
      video_start: true,
      total_duration: 80000
    }) 

    @video_watch_event_3 = visit.events.create(name: 'test-video-watched', user_id: 1, time: Time.now,  properties: {
      label: "watched_this_video",
      category: "video_view",
      page_id: 1,
      watch_time: 20000,
      resource_id: api_resource.id,
      video_start: false,
      total_duration: 40000
    })
  end 
end