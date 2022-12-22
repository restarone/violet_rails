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

  # API Accessibilities
  def ensure_authority_for_full_access_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:full_access])
      flash.alert = "You do not have the permission to do that. Only users with full_access are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_full_read_access_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:full_read_access_in_api_namespace])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_read_access or delete_access_api_namespace_only or allow_exports or allow_duplication or full_access_api_namespace_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_full_access_in_api_namespace_only
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:full_access_api_namespace_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_delete_access_in_api_namespace_only
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:delete_access_api_namespace_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or delete_access_api_namespace_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_read_api_resources_only_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:read_api_resources_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_resources_only or read_api_resources_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_full_access_for_api_resources_only_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:full_access_for_api_resources_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_access_for_api_resources_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_delete_access_for_api_resources_only_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:delete_access_for_api_resources_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_access_for_api_resources_only or delete_access_for_api_resources_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_allow_exports_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:allow_exports])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_exports are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_allow_duplication_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:allow_duplication])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_duplication are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_allow_social_share_metadata_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:allow_social_share_metadata])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_social_share_metadata are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_read_api_actions_only_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:read_api_actions_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_api_actions_only or read_api_actions_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_full_access_for_api_actions_only_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:full_access_for_api_actions_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_read_external_api_connections_only_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:read_external_api_connections_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_external_api_connections_only or read_external_api_connections_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_full_access_for_external_api_connections_only_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:full_access_for_external_api_connections_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_full_access_for_api_form_only_in_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:full_access_for_api_form_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_access_for_api_form_only are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_read_api_keys_only_in_api
    unless user_authorized_for_api_keys_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:read_api_keys_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or read_access or delete_acess for ApiKeys are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_full_access_for_api_keys_only_in_api
    unless user_authorized_for_api_keys_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:full_access_for_api_keys_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access for ApiKeys are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_delete_access_for_api_keys_only_in_api
    unless user_authorized_for_api_keys_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:delete_access_for_api_keys_only])
      flash.alert = "You do not have the permission to do that. Only users with full_access or delete_access for ApiKeys are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  def ensure_authority_for_viewing_all_api
    unless user_authorized_to_view_all_api?(ApiNamespace::API_ACCESSIBILITIES[:full_read_access_in_api_namespace])
      flash.alert = "You do not have the permission to do that. Only users with access in ApiNamespaces or access in ApiKeys are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  # For new, create action of api_namespaces_controller, we cannot use the category specicfic authorization
  def ensure_authority_for_creating_api
    unless user_authorized_for_api_accessibility?(ApiNamespace::API_ACCESSIBILITIES[:full_access_api_namespace_only], check_categories: false)
      flash.alert = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only for all_namespaces are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end

  private
  def user_authorized_for_api_accessibility?(api_permissions, check_categories: true)
    return false unless current_user.api_accessibility['api_namespaces'].present?

    api_namespaces_accessibility = current_user.api_accessibility['api_namespaces']

    is_user_authorized = false

    if api_namespaces_accessibility.keys.include?('all_namespaces')
      is_user_authorized = api_permissions.any? do |access_name|
        api_namespaces_accessibility.dig('all_namespaces', access_name).present? && api_namespaces_accessibility.dig('all_namespaces', access_name) == 'true'
      end
    elsif check_categories && api_namespaces_accessibility.keys.include?('namespaces_by_category')
      categories = @api_namespace.categories.pluck(:label)

      if categories.blank? && api_namespaces_accessibility.dig('namespaces_by_category', 'uncategorized').present?
        is_user_authorized = api_permissions.any? do |access_name|
          api_namespaces_accessibility.dig('namespaces_by_category', 'uncategorized', access_name).present? && api_namespaces_accessibility.dig('namespaces_by_category', 'uncategorized', access_name) == 'true'
        end
      else
        categories.any? do |category|
          is_user_authorized = api_permissions.any? do |access_name|
            api_namespaces_accessibility.dig('namespaces_by_category', category, access_name).present? && api_namespaces_accessibility.dig('namespaces_by_category', category, access_name) == 'true'
          end
        end
      end
    end

    is_user_authorized
  end

  def user_authorized_to_view_all_api?(api_permissions)
    return false unless current_user.api_accessibility.keys.present?

    api_namespaces_accessibility = current_user.api_accessibility['api_namespaces']
    api_keys_accessibility = current_user.api_accessibility['api_keys']

    is_user_authorized = false

    if api_namespaces_accessibility.present? && api_namespaces_accessibility.keys.include?('all_namespaces')
      is_user_authorized = api_permissions.any? do |access_name|
        api_namespaces_accessibility.dig('all_namespaces', access_name).present? && api_namespaces_accessibility.dig('all_namespaces', access_name) == 'true'
      end
    elsif api_namespaces_accessibility.present? && api_namespaces_accessibility.keys.include?('namespaces_by_category')
      categories = api_namespaces_accessibility.dig('namespaces_by_category').keys

      categories.any? do |category|
        is_user_authorized = api_permissions.any? do |access_name|
          api_namespaces_accessibility.dig('namespaces_by_category', category, access_name).present? && api_namespaces_accessibility.dig('namespaces_by_category', category, access_name) == 'true'
        end
      end
    elsif api_keys_accessibility.present?
      is_user_authorized = ApiNamespace::API_ACCESSIBILITIES[:read_api_keys_only].any? do |access_name|
        api_keys_accessibility.dig(access_name).present? && api_keys_accessibility.dig(access_name) == 'true'
      end
    end

    is_user_authorized
  end

  def user_authorized_for_api_keys_accessibility?(api_permissions)
    return false unless current_user.api_accessibility['api_keys'].present?

    api_keys_accessibility = current_user.api_accessibility['api_keys']
    is_user_authorized = api_permissions.any? do |access_name|
      api_keys_accessibility[access_name].present? && api_keys_accessibility[access_name] == 'true'
    end

    is_user_authorized
  end
end