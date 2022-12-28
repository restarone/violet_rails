class Comfy::Admin::V2::DashboardController < Comfy::Admin::Cms::BaseController
  include AhoyEventsHelper

  before_action :ensure_authority_to_manage_analytics

  def dashboard
    @page_visit_events = Ahoy::Event.where(name: 'comfy-cms-page-visit').joins(:visit)
    @page_visit_events = @page_visit_events.jsonb_search(:properties, { page_id: params[:page] }) if params[:page].present?

    @start_date = params[:start_date]&.to_date || Date.today.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.today.end_of_month
    @page_visit_events = @page_visit_events.where(time: @start_date..@end_date)

    @visits = Ahoy::Visit.where(started_at: @start_date..@end_date)
  end
end
