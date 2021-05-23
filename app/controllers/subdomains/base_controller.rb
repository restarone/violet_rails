class Subdomains::BaseController < ApplicationController
  skip_before_action :track_ahoy_visit
  before_action :authenticate_user!
  before_action :ensure_user_belongs_to_subdomain
  layout "subdomains"

  def ensure_user_belongs_to_subdomain
    unless User.find_by(id: current_user.id)
      flash.alert = 'You arent not authorized to visit that page'
      redirect_to root_url
    end
  end
end