class Comfy::Admin::V2::DashboardController < Comfy::Admin::Cms::BaseController
  include AhoyEventsHelper

  before_action :ensure_authority_to_manage_analytics

  def dashboard
    @start_date = params[:start_date]&.to_date || Date.today.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.today.end_of_month


    @visits = Ahoy::Visit.where(started_at: @start_date.beginning_of_day..@end_date.end_of_day)

    @page_visit_events = Ahoy::Event.jsonb_search(:properties, { category: 'page_visit' }).joins(:visit)
    @click_events = Ahoy::Event.jsonb_search(:properties, { category: 'click' }).joins(:visit)
    @video_watch_events = Ahoy::Event.jsonb_search(:properties, { category: 'video_view' }).joins(:visit)

    if params[:page].present?
      @page_visit_events = @page_visit_events.jsonb_search(:properties, { page_id: params[:page] })
      @click_events = @click_events.jsonb_search(:properties, { page_id: params[:page] })
      @video_watch_events = @video_watch_events.jsonb_search(:properties, { page_id: params[:page] })
    end

    @pervious_period_page_visit_events = @page_visit_events.where(time: previous_period(params[:interval], @start_date, @end_date))
    @pervious_period_click_events = @click_events.where(time: previous_period(params[:interval], @start_date, @end_date))
    @pervious_period_video_watch_events = @video_watch_events.where(time: previous_period(params[:interval], @start_date, @end_date))

    date_range = @start_date.beginning_of_day..@end_date.end_of_day
    @page_visit_events = @page_visit_events.where(time: date_range)
    @click_events = @click_events.where(time: date_range)
    @video_watch_events = @video_watch_events.where(time: date_range)
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