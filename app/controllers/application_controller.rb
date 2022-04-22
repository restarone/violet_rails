class ApplicationController < ActionController::Base
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
end
