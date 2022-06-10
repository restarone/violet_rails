class Subdomains::BaseController < ApplicationController
  skip_before_action :track_ahoy_visit, raise: false
  before_action :authenticate_user!
  before_action :ensure_user_belongs_to_subdomain
  layout "subdomains"

  def ensure_user_belongs_to_subdomain
    unless User.find_by(id: current_user.id)
      flash.alert = 'You arent not authorized to visit that page'
      redirect_to root_url
    end
  end

  def ensure_authority_to_manage_web
    unless current_user.can_manage_web
      flash.alert = "You do not have the permission to do that. Only users who can_manage_web are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_to_manage_analytics
    unless current_user.can_manage_analytics
      flash.alert = "You do not have the permission to do that. Only users who can_manage_analytics are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_to_manage_files
    unless current_user.can_manage_files
      flash.alert = "You do not have the permission to do that. Only users who can_manage_files are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_to_manage_web_settings
    unless current_user.can_manage_subdomain_settings
      flash.alert = "You do not have the permission to do that. Only users who can_manage_subdomain_settings are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_to_manage_users
    unless current_user.can_manage_users
      flash.alert = "You do not have the permission to do that. Only users who can-manage-users  are allowed to perform that action."
      redirect_to comfy_admin_cms_path
    end
  end

  def ensure_authority_to_manage_api
    unless current_user.can_manage_api
      flash.alert = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end
end