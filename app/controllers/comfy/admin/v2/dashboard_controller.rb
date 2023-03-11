class Comfy::Admin::V2::DashboardController < Comfy::Admin::Cms::BaseController
  include AhoyEventsHelper

  before_action :ensure_authority_to_manage_analytics

  def dashboard
    @start_date = params[:start_date]&.to_date || Date.today.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.today.end_of_month
    date_range = @start_date.beginning_of_day..@end_date.end_of_day

    @visits = Ahoy::Visit.where(started_at: date_range)

    filtered_events = Ahoy::Event.joins(:visit)

    Ahoy::Event::EVENT_CATEGORIES.values.each do |event_category|
      if event_category == Ahoy::Event::EVENT_CATEGORIES[:page_visit]
        events = filtered_events.where(name: 'comfy-cms-page-visit')
      else
        events = filtered_events.jsonb_search(:properties, { category: event_category })
      end
      events = events.jsonb_search(:properties, { page_id: params[:page] }) if params[:page].present?
      instance_variable_set("@previous_period_#{event_category}_events", events.where(time: previous_period(params[:interval], @start_date, @end_date)))
      instance_variable_set("@#{event_category}_events", events.where(time: date_range))
    end

    # legacy and system events does not have category 
    # separating out 'comfy-cms-page-visit' event since we have a seprate section
    @legacy_and_system_events = filtered_events.where.not('properties::jsonb ? :key', key: 'category').where.not(name: 'comfy-cms-page-visit')
    @previous_period_legacy_and_system_events = @legacy_and_system_events.where(time: previous_period(params[:interval], @start_date, @end_date))
    @legacy_and_system_events = @legacy_and_system_events.where(time: date_range)
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
end