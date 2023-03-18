class Comfy::Admin::V2::DashboardController < Comfy::Admin::Cms::BaseController
  include DashboardHelper

  before_action :ensure_authority_to_manage_analytics

  def dashboard
    @start_date = params[:start_date]&.to_date || Date.today.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.today.end_of_month

    set_event_category_specific_analytics_data
  end


  private

  def previous_period(interval, start_date, end_date)
    today = Date.current
    interval = interval || today.strftime('%B %Y')

    case interval
    when "#{today.strftime('%B %Y')}"
      today.prev_month.beginning_of_month.beginning_of_day..today.prev_month.end_of_month.end_of_day
    when "3 months"
      (start_date - 3.months).beginning_of_month.beginning_of_day..(start_date - 1.month).end_of_month.end_of_day
    when "6 months"
      (today - 6.months).beginning_of_month.beginning_of_day..(start_date - 1.month).end_of_month.end_of_day
    when "1 year"
      (today - 12.months).beginning_of_month.beginning_of_day..(start_date - 1.month).end_of_month.end_of_day
    else

      days_diff = (end_date - start_date).to_i
      (start_date - (days_diff + 1).days).beginning_of_day..(start_date - 1.day).end_of_day
    end
  end

  def set_event_category_specific_analytics_data
    Ahoy::Event::EVENT_CATEGORIES.values.each do |event_category|
      if event_category == Ahoy::Event::EVENT_CATEGORIES[:page_visit]
        current_events_sql = params[:page].present? ? Ahoy::Event.joins(:visit).jsonb_search(:properties, { page_id: params[:page] }).where(name: 'comfy-cms-page-visit').where(time: @start_date.beginning_of_day..@end_date.end_of_day).to_sql : Ahoy::Event.joins(:visit).where(name: 'comfy-cms-page-visit').where(time: @start_date.beginning_of_day..@end_date.end_of_day).to_sql
        previous_events_sql = params[:page].present? ? Ahoy::Event.joins(:visit).jsonb_search(:properties, { page_id: params[:page] }).where(name: 'comfy-cms-page-visit').where(time: previous_period(params[:interval], @start_date, @end_date)).to_sql : Ahoy::Event.joins(:visit).where(name: 'comfy-cms-page-visit').where(time: previous_period(params[:interval], @start_date, @end_date)).to_sql
      elsif event_category == Ahoy::Event::EVENT_CATEGORIES[:video_view]
        current_events_sql = params[:page].present? ? Ahoy::Event.joins(:visit).jsonb_search(:properties, { page_id: params[:page] }).jsonb_search(:properties, { category: event_category }).filter_records_with_video_details_missing.where(time: @start_date.beginning_of_day..@end_date.end_of_day).to_sql : Ahoy::Event.joins(:visit).jsonb_search(:properties, { category: event_category }).filter_records_with_video_details_missing.where(time: @start_date.beginning_of_day..@end_date.end_of_day).to_sql
        previous_events_sql = params[:page].present? ? Ahoy::Event.joins(:visit).jsonb_search(:properties, { page_id: params[:page] }).jsonb_search(:properties, { category: event_category }).filter_records_with_video_details_missing.where(time: previous_period(params[:interval], @start_date, @end_date)).to_sql : Ahoy::Event.joins(:visit).jsonb_search(:properties, { category: event_category }).filter_records_with_video_details_missing.where(time: previous_period(params[:interval], @start_date, @end_date)).to_sql
      else
        current_events_sql = params[:page].present? ? Ahoy::Event.joins(:visit).jsonb_search(:properties, { page_id: params[:page] }).jsonb_search(:properties, { category: event_category }).where(time: @start_date.beginning_of_day..@end_date.end_of_day).to_sql : Ahoy::Event.joins(:visit).jsonb_search(:properties, { category: event_category }).where(time: @start_date.beginning_of_day..@end_date.end_of_day).to_sql
        previous_events_sql = params[:page].present? ? Ahoy::Event.joins(:visit).jsonb_search(:properties, { page_id: params[:page] }).jsonb_search(:properties, { category: event_category }).where(time: previous_period(params[:interval], @start_date, @end_date)).to_sql : Ahoy::Event.joins(:visit).jsonb_search(:properties, { category: event_category }).where(time: previous_period(params[:interval], @start_date, @end_date)).to_sql
      end

      if event_category == Ahoy::Event::EVENT_CATEGORIES[:page_visit]
        instance_variable_set("@#{event_category}_events", {
          events_exists: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").size > 0,
          events_count: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").size,
          previous_period_events_count: Ahoy::Event.from("(#{previous_events_sql}) as ahoy_events").size,
          column_chart_data: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").page_visit_chart_data_for_page_visit_events(@start_date..@end_date, split_into(@start_date, @end_date)),
          pie_chart_data: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").visitors_chart_data_for_page_visit_events
        })
      elsif event_category == Ahoy::Event::EVENT_CATEGORIES[:video_view]
        current_top_videos_hash = Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").top_three_videos_details
        previous_top_videos_hash = Ahoy::Event.from("(#{previous_events_sql}) as ahoy_events").total_views_and_watch_time_detals_for_previous_video_events(current_top_videos_hash.map { |video| video[:resource_id] })

        instance_variable_set("@#{event_category}_events", {
          events_exists: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").size > 0,
          events_count: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").size,
          previous_period_events_count: Ahoy::Event.from("(#{previous_events_sql}) as ahoy_events").size,
          watch_time: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").total_watch_time_for_video_events,
          previous_watch_time: Ahoy::Event.from("(#{previous_events_sql}) as ahoy_events").total_watch_time_for_video_events,
          avg_view_duration: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").avg_view_duration_for_video_events,
          previous_avg_view_duration: Ahoy::Event.from("(#{previous_events_sql}) as ahoy_events").avg_view_duration_for_video_events,
          avg_view_percent: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").avg_view_percentage_for_video_events,
          previous_avg_view_percent: Ahoy::Event.from("(#{previous_events_sql}) as ahoy_events").avg_view_percentage_for_video_events,
          top_videos: top_three_videos_details(current_top_videos_hash, previous_top_videos_hash)
        })
      else
        instance_variable_set("@#{event_category}_events", {
          events_exists: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").size > 0,
          events_count: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").size,
          label_grouped_events: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").with_label.group(:label).size,
          previous_period_events_count: Ahoy::Event.from("(#{previous_events_sql}) as ahoy_events").size,
          previous_label_grouped_events: Ahoy::Event.from("(#{previous_events_sql}) as ahoy_events").with_label.group(:label).size
        })
      end

    end

    # legacy and system events does not have category 
    # separating out 'comfy-cms-page-visit' event since we have a seprate section
    current_events_sql = Ahoy::Event.joins(:visit).where.not('properties::jsonb ? :key', key: 'category').where.not(name: 'comfy-cms-page-visit').where(time: @start_date.beginning_of_day..@end_date.end_of_day).to_sql
    previous_events_sql = Ahoy::Event.joins(:visit).where.not('properties::jsonb ? :key', key: 'category').where.not(name: 'comfy-cms-page-visit').where(time: previous_period(params[:interval], @start_date, @end_date)).to_sql

    @legacy_and_system_events = {
      events_exists: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").size > 0,
      events_count: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").size,
      label_grouped_events: Ahoy::Event.from("(#{current_events_sql}) as ahoy_events").with_label.group(:label).size,
      previous_period_events_count: Ahoy::Event.from("(#{previous_events_sql}) as ahoy_events").size,
      previous_label_grouped_events: Ahoy::Event.from("(#{previous_events_sql}) as ahoy_events").with_label.group(:label).size
    }

    GC.start
  end
end