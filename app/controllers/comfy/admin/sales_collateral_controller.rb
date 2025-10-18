class Comfy::Admin::SalesCollateralController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_analytics

  def dashboard
  end
end