class Subdomains::BaseController < ApplicationController
  skip_before_action :track_ahoy_visit, raise: false
  before_action :authenticate_user!
  before_action :ensure_user_belongs_to_subdomain
  layout "subdomains"

  API_ACCESSIBILITIES = {
    full_read_access: ['full_access', 'full_read_access'],
    full_access: ['full_access'],
    read_api_resources_only: ['full_access', 'full_read_access', 'read_api_resources_only'],
    allow_exports: ['full_access', 'allow_exports'],
    allow_duplication: ['full_access', 'allow_duplication'],
  }

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

  # API Accessibilities
  def ensure_authority_for_full_read_access_in_api
    unless user_authorized_for_api_accessibility?(API_ACCESSIBILITIES[:full_read_access])
      flash.alert = "You do not have the permission to do that. Only users with full_read_access or full_access are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_full_access_in_api
    unless user_authorized_for_api_accessibility?(API_ACCESSIBILITIES[:full_access])
      flash.alert = "You do not have the permission to do that. Only users with full_access are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_read_api_resources_only_in_api
    unless user_authorized_for_api_accessibility?(API_ACCESSIBILITIES[:read_api_resources_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_read_access or read_api_resources_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_allow_exports_in_api
    unless user_authorized_for_api_accessibility?(API_ACCESSIBILITIES[:allow_exports])
      flash.alert = "You do not have the permission to do that. Only users with full_access or allow_exports are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_allow_duplication_in_api
    unless user_authorized_for_api_accessibility?(API_ACCESSIBILITIES[:allow_duplication])
      flash.alert = "You do not have the permission to do that. Only users with full_access or allow_duplication are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  private
  def user_authorized_for_api_accessibility?(api_permissions)
    user_api_accessibility = current_user.api_accessibility

    return false unless user_api_accessibility.present?

    is_user_authorized = false

    if user_api_accessibility.keys.include?('all_namespaces')
      is_user_authorized = api_permissions.any? do |access_name|
        user_api_accessibility.dig('all_namespaces', access_name).present? && user_api_accessibility.dig('all_namespaces', access_name) == 'true'
      end
    elsif user_api_accessibility.keys.include?('namespaces_by_category')
      categories = @api_namespace.categories.pluck(:label)

      if categories.blank? && user_api_accessibility.dig('namespaces_by_category', 'uncategorized').present?
        is_user_authorized = api_permissions.any? do |access_name|
          user_api_accessibility.dig('namespaces_by_category', 'uncategorized', access_name).present? && user_api_accessibility.dig('namespaces_by_category', 'uncategorized', access_name) == 'true'
        end
      else
        categories.any? do |category|
          is_user_authorized = api_permissions.any? do |access_name|
            user_api_accessibility.dig('namespaces_by_category', category, access_name).present? && user_api_accessibility.dig('namespaces_by_category', category, access_name) == 'true'
          end
        end
      end
    end

    is_user_authorized
  end
end