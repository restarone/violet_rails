require "test_helper"

class Event < ActiveSupport::TestCase
  include DashboardHelper

  setup do
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
  
  test 'total watch time' do
    assert_equal 30000, Ahoy::Event.where(id: [@video_watch_event_1, @video_watch_event_2].map(&:id)).total_watch_time_for_video_events
  end

  test 'total_views' do
    assert_equal 2, Ahoy::Event.where(id: [@video_watch_event_1, @video_watch_event_2, @video_watch_event_3].map(&:id)).total_views_for_video_events
  end

  test 'avg_view_duration' do
    assert_equal 25000.0, Ahoy::Event.where(id: [@video_watch_event_1, @video_watch_event_2, @video_watch_event_3].map(&:id)).avg_view_duration_for_video_events
  end

  test 'avg_view_percentange' do
    assert_equal 50.0, Ahoy::Event.where(id: [@video_watch_event_1, @video_watch_event_2, @video_watch_event_3].map(&:id)).avg_view_percentage_for_video_events
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
      assert_equal [{:name=>"Desktop", :data=>{"#{2.days.ago.strftime('%-d %^b %Y')}"=>0, "#{1.days.ago.strftime('%-d %^b %Y')}"=>1, "#{Time.now.strftime('%-d %^b %Y')}"=>1}}], Ahoy::Event.where(name: 'test-page-view').joins(:visit).page_visit_chart_data_for_page_visit_events(2.days.ago.to_date..Time.now.to_date, split_into(2.days.ago.to_date, Time.now.to_date))

      # should split into weeks
      assert_equal [{:name=>"Desktop", :data=>{"#{4.weeks.ago.strftime('%V')}"=>0, "#{3.weeks.ago.strftime('%V')}"=>0, "#{2.weeks.ago.strftime('%V')}"=>0, "#{1.weeks.ago.strftime('%V')}"=>2, "#{Time.now.strftime('%V')}"=>0}}], Ahoy::Event.where(name: 'test-page-view').joins(:visit).page_visit_chart_data_for_page_visit_events(Time.now.beginning_of_month.to_date..Time.now.end_of_month.to_date, split_into(Time.now.beginning_of_month.to_date, Time.now.end_of_month.to_date))

      # should split into months
      assert_equal [{:name=>"Desktop", :data=>{"#{2.months.ago.strftime('%^b %Y')}"=>1, "#{1.months.ago.strftime('%^b %Y')}"=>0, "#{Time.now.strftime('%^b %Y')}"=>2}}], Ahoy::Event.where(name: 'test-page-view').joins(:visit).page_visit_chart_data_for_page_visit_events(2.months.ago.to_date..Time.now.to_date, split_into(2.months.ago.to_date, Time.now.to_date))

      # should split into years
      assert_equal [{:name=>"Desktop", :data=>{"#{2.years.ago.strftime('%Y')}"=>1, "#{1.years.ago.strftime('%Y')}"=>2, "#{Time.now.strftime('%Y')}"=>2}}], Ahoy::Event.where(name: 'test-page-view').joins(:visit).page_visit_chart_data_for_page_visit_events(2.years.ago.to_date..Time.now.to_date, split_into(2.years.ago.to_date, Time.now.to_date))
    end
  end
end