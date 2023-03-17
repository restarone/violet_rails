class Comfy::Admin::V2::DashboardController < Comfy::Admin::Cms::BaseController
  include DashboardHelper

  before_action :ensure_authority_to_manage_analytics

  def dashboard
    @start_date = params[:start_date]&.to_date || Date.today.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.today.end_of_month
    date_range = @start_date.beginning_of_day..@end_date.end_of_day

    # @visits = Ahoy::Visit.where(started_at: date_range)

    # filtered_events = Ahoy::Event.joins(:visit)

    set_event_category_specific_analytics_data

    # Ahoy::Event::EVENT_CATEGORIES.values.each do |event_category|
    #   if event_category == Ahoy::Event::EVENT_CATEGORIES[:page_visit]
    #     events = filtered_events.where(name: 'comfy-cms-page-visit')
    #   else
    #     events = filtered_events.jsonb_search(:properties, { category: event_category })
    #   end
    #   events = events.jsonb_search(:properties, { page_id: params[:page] }) if params[:page].present?
    #   instance_variable_set("@previous_period_#{event_category}_events", events.where(time: previous_period(params[:interval], @start_date, @end_date)))
    #   instance_variable_set("@#{event_category}_events", events.where(time: date_range))
    # end

    # # legacy and system events does not have category 
    # # separating out 'comfy-cms-page-visit' event since we have a seprate section
    # @legacy_and_system_events = filtered_events.where.not('properties::jsonb ? :key', key: 'category').where.not(name: 'comfy-cms-page-visit')
    # @previous_period_legacy_and_system_events = @legacy_and_system_events.where(time: previous_period(params[:interval], @start_date, @end_date))
    # @legacy_and_system_events = @legacy_and_system_events.where(time: date_range)
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
    # GC.start(full_mark: true)
    filtered_events = Ahoy::Event.joins(:visit)
    filtered_events = filtered_events.jsonb_search(:properties, { page_id: params[:page] }) if params[:page].present?

    Ahoy::Event::EVENT_CATEGORIES.values.each do |event_category|
      if event_category == Ahoy::Event::EVENT_CATEGORIES[:page_visit]
        events = filtered_events.where(name: 'comfy-cms-page-visit')
      elsif event_category == Ahoy::Event::EVENT_CATEGORIES[:video_view]
        events = filtered_events.jsonb_search(:properties, { category: event_category }).filter_records_with_video_details_missing
      else
        events = filtered_events.jsonb_search(:properties, { category: event_category })
      end

      # events = events.filter_records_with_video_details_missing if event_category == Ahoy::Event::EVENT_CATEGORIES[:video_view]

      # instance_variable_set("@previous_period_#{event_category}_events", events.where(time: previous_period(params[:interval], @start_date, @end_date)))
      # instance_variable_set("@#{event_category}_events", events.where(time: @start_date.beginning_of_day..@end_date.end_of_day))

      # current_event_ids = events.where(time: @start_date.beginning_of_day..@end_date.end_of_day).pluck(:id)
      current_events = events.where(time: @start_date.beginning_of_day..@end_date.end_of_day).load

      # If no events are present for the category, further calculations are skipped.
      # next if current_event_ids.empty?
      next if current_events.empty?

      # previous_period_event_ids = events.where(time: previous_period(params[:interval], @start_date, @end_date)).pluck(:id)
      previous_period_events = events.where(time: previous_period(params[:interval], @start_date, @end_date)).load

      if event_category == Ahoy::Event::EVENT_CATEGORIES[:page_visit]
        instance_variable_set("@#{event_category}_events", {
          events_exists: true,
          events_count: current_events.size,
          previous_period_events_count: previous_period_events.size,
          column_chart_data: current_events.page_visit_chart_data_for_page_visit_events(@start_date..@end_date, split_into(@start_date, @end_date)),
          pie_chart_data: current_events.visitors_chart_data_for_page_visit_events
        })
      elsif event_category == Ahoy::Event::EVENT_CATEGORIES[:video_view]
        current_top_videos_hash = current_events.top_three_videos_details
        previous_top_videos_hash = previous_period_events.total_views_and_watch_time_detals_for_previous_video_events(current_top_videos_hash.map { |video| video[:resource_id] })

        instance_variable_set("@#{event_category}_events", {
          events_exists: true,
          events_count: current_events.size,
          previous_period_events_count: previous_period_events.size,
          watch_time: current_events.total_watch_time_for_video_events,
          previous_watch_time: previous_period_events.total_watch_time_for_video_events,
          avg_view_duration: current_events.avg_view_duration_for_video_events,
          previous_avg_view_duration: previous_period_events.avg_view_duration_for_video_events,
          avg_view_percent: current_events.avg_view_percentage_for_video_events,
          previous_avg_view_percent: previous_period_events.avg_view_percentage_for_video_events,
          top_videos: top_three_videos_details(current_top_videos_hash, previous_top_videos_hash)
        })
      else
        instance_variable_set("@#{event_category}_events", {
          events_exists: true,
          events_count: current_events.size,
          label_grouped_events: current_events.with_label.group(:label).size,
          previous_period_events_count: previous_period_events.size,
          previous_label_grouped_events: previous_period_events.with_label.group(:label).size
        })
      end

    end

    # legacy and system events does not have category 
    # separating out 'comfy-cms-page-visit' event since we have a seprate section
    legacy_and_system_events = Ahoy::Event.joins(:visit).where.not('properties::jsonb ? :key', key: 'category').where.not(name: 'comfy-cms-page-visit')
    # current_event_ids = legacy_and_system_events.where(time: @start_date.beginning_of_day..@end_date.end_of_day).pluck(:id)
    current_events = legacy_and_system_events.where(time: @start_date.beginning_of_day..@end_date.end_of_day).load

    if current_events.any?
      # previous_period_event_ids = legacy_and_system_events.where(time: previous_period(params[:interval], @start_date, @end_date)).pluck(:id)
      previous_period_events = legacy_and_system_events.where(time: previous_period(params[:interval], @start_date, @end_date)).load

      @legacy_and_system_events = {
        events_exists: true,
        events_count: current_events.size,
        label_grouped_events: current_events.with_label.group(:label).size,
        previous_period_events_count: previous_period_events.size,
        previous_label_grouped_events: previous_period_events.with_label.group(:label).size
      }
    end

    # GC.start
    GC.start(full_mark: true)
  end
end