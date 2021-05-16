class Subdomains::Admin::BaseController < Subdomains::BaseController
  before_action :authenticate_user!, :ensure_user_belongs_to_subdomain
  layout "subdomains"

  private

  def ensure_user_belongs_to_subdomain
    Apartment::Tenant.switch Apartment::Tenant.current do
      unless User.find_by(email: current_user.email)
        flash.alert = 'You do not have access to that'
        redirect_to root_path
      end
    end
  end
end 