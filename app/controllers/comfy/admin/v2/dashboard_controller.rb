class Comfy::Admin::V2::DashboardController < Comfy::Admin::Cms::BaseController
  include AhoyEventsHelper

  before_action :ensure_authority_to_manage_analytics

  def dashboard
    @page_visit_events = Ahoy::Event.where(name: 'comfy-cms-page-visit').joins(:visit)
    @page_visit_events = @page_visit_events.jsonb_search(:properties, { page_id: params[:page] }) if params[:page].present?

    @start_date = params[:start_date]&.to_date || Date.today.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.today.end_of_month

    @pervious_period_page_visit_events = @page_visit_events.where(time: previous_period((params[:interval] || Date.current.strftime('%B %Y')), @start_date, @end_date))

    @page_visit_events = @page_visit_events.where(time: @start_date..@end_date)

    @visits = Ahoy::Visit.where(started_at: @start_date..@end_date)
  end

  def previous_period(interval, start_date, end_date)
    today = Date.current

    case interval
    when "#{today.strftime('%B %Y')}"
      today.prev_month.beginning_of_month..today.prev_month.end_of_month
    when "3 months"
      (start_date - 3.months).beginning_of_month..(start_date - 1.month).end_of_month
    when "6 months"
      (today - 6.months).beginning_of_month..(start_date - 1.month).end_of_month
    when "1 year"
      (today - 12.months).beginning_of_month..(start_date - 1.month).end_of_month
    else
      days_diff = (end_date - start_date).to_i
      (start_date - days_diff.days)..(start_date - 1.day)
    end
  end
end