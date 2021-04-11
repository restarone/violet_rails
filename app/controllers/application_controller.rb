class ApplicationController < ActionController::Base

  def after_sign_in_path_for(resource)
    if session[:user_return_to] then return session[:user_return_to] end
    if resource.class == User
      root_url(subdomain: Apartment::Tenant.current)
    end
  end

end
