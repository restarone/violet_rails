class Comfy::Admin::V2::DashboardController < Comfy::Admin::Cms::BaseController
  include AhoyEventsHelper

  before_action :ensure_authority_to_manage_analytics

  def dashboard
    @page_visit_events_q = Ahoy::Event.where(name: 'comfy-cms-page-visit').joins(:visit).ransack(params[:q])
    @page_visit_events = @page_visit_events_q.result
    @page_visit_events = @page_visit_events.jsonb_search(:properties, JSON.parse(params[:properties]).to_hash, params[:match]) if params[:properties]
    @page_visit_data = @page_visit_events.where.not('ahoy_visits.device_type': nil).group_by { |u| u.visit.device_type }.map do |key, value|
      { name: key, data: Ahoy::Event.where(id: value.pluck(:id)).group_by_week(:time).count }
    end
  end
end
