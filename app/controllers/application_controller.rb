class ApplicationController < ActionController::Base

  def after_sign_in_path_for(resource)
    if session[:customer_return_to] then return session[:customer_return_to] end
    if resource.class == Customer
      root_url(subdomain: resource.subdomain)
    end
  end

end
