class Comfy::Admin::DashboardController < Comfy::Admin::Cms::BaseController
  include AhoyEventsHelper

  before_action :ensure_authority_to_manage_analytics
  before_action :set_visit, only: [:visit]

  def dashboard
    params[:q] ||= {}
    @visits_q = Subdomain.current.ahoy_visits.ransack(params[:q])
    @visits = @visits_q.result.paginate(page: params[:page], per_page: 10)
  end

  def visit
    @visit_specific_events_q = Ahoy::Event.where(visit_id: @visit.id).order(time: :asc).ransack(params[:q])
    @visit_specific_events = @visit_specific_events_q.result.paginate(page: params[:page], per_page: 10)
  end

  def events_detail
    @events_q = Ahoy::Event.where(name: params[:ahoy_event_type]).joins(:visit).ransack(params[:q])
    @events = @events_q.result.paginate(page: params[:page], per_page: 10)

    @event_visits_s = Ahoy::Visit.where(id: @events_q.result.pluck(:visit_id).uniq).ransack(params[:s], search_key: :s)
    @event_visits = @event_visits_s.result.paginate(page: params[:page], per_page: 10)
  end

  def events_list
    @events_list_q = Ahoy::Event.group(:name).select("DISTINCT(name) AS distinct_name", "MIN(time) AS first_created_at", "COUNT(name) AS count").order(:name).ransack(params[:q])
    @events_list = @events_list_q.result.paginate(page: params[:page], per_page: 10)
  end

  def destroy_specific_events
    response = Ahoy::Event.delete_specific_events_and_associated_visits(delete_events: true, event_type: params[:ahoy_event_type])

    if response[:success]
      redirect_to dashboard_events_list_path, notice: response[:message]
    else
      redirect_to dashboard_events_list_path, alert: "Deleting specific events failed due to: #{response[:message]}"
    end
  end

  def destroy_associated_visits_of_specific_events
    response = Ahoy::Event.delete_specific_events_and_associated_visits(delete_events: false, event_type: params[:ahoy_event_type])

    if response[:success]
      redirect_to dashboard_events_list_path, notice: response[:message]
    else
      redirect_to dashboard_events_list_path, alert: "Deleting associated visits of specific events failed due to: #{response[:message]}"
    end
  end

  private

  def set_visit
    @visit = Ahoy::Visit.find_by(id: params[:ahoy_visit_id])
  end

  
end
