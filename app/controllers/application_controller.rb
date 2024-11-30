class ApplicationController < ActionController::Base
  include ActiveStorage::SetCurrent

  before_action :store_user_location!, if: :storable_location?
  before_action :prepare_profiler,:prepare_exception_notifier , :set_current_user

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
  
  def require_global_admin
    redirect_to root_path unless current_user && current_user.global_admin?
  end


  private

  def prepare_exception_notifier
    request.env["exception_notifier.exception_data"] = {
      current_user: current_user,
      current_visit: current_visit
    }
  end

  def prepare_profiler
    if current_user && current_user.can_access_admin? && current_user.show_profiler?
      return if params[:pp].present? && params[:pp] == 'env' && !current_user.global_admin?
      Rack::MiniProfiler.authorize_request
    end
  end

  # Reference: https://github.com/heartcombo/devise/wiki/How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update#storelocation-to-the-rescue
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr? 
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  def set_current_user
    Current.user = current_user
  end
end
