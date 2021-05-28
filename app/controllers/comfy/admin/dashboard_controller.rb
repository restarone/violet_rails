class Comfy::Admin::DashboardController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_web
  def dashboard
    params[:q] ||= {}
    @visits_q = Subdomain.current.ahoy_visits.ransack(params[:q])
    @visits = @visits_q.result.paginate(page: params[:page], per_page: 10)
  end
end
