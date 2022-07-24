class ApplicationController < ActionController::Base

  before_action :prepare_exception_notifier
  before_action :store_user_location!, if: :storable_location?

  def after_sign_in_path_for(resource)
    if session[:user_return_to] then return session[:user_return_to] end
    after_sign_in_path = Subdomain.current.after_sign_in_path
    if resource.class == User
      if resource.global_admin
        admin_subdomain_requests_path
      elsif resource.can_access_admin
        comfy_admin_cms_path
      elsif after_sign_in_path
        after_sign_in_path
      else
        # tenant
        root_url(subdomain: Apartment::Tenant.current)
      end
    end
  end

  def after_accept_path_for(resource)
    after_sign_up_path = Subdomain.current.after_sign_up_path
    if after_sign_up_path
      return after_sign_up_path
    else
      return root_url(subdomain: Apartment::Tenant.current)
    end
  end


  private

  def prepare_exception_notifier
    request.env["exception_notifier.exception_data"] = {
      current_user: current_user,
      current_visit: current_visit
    }
  end

  # Reference: https://github.com/heartcombo/devise/wiki/How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update#storelocation-to-the-rescue
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr? 
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end
end
