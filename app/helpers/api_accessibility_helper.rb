module ApiAccessibilityHelper
  def has_access_to_main_category?(api_accessibility, top_category)
    api_accessibility.dig('api_namespaces', top_category).present?
  end

  def has_access_to_specific_category?(api_accessibility, category_label)
    api_accessibility.dig('api_namespaces', 'namespaces_by_category', category_label).present?
  end

  def has_sub_access_to_specific_category?(api_accessibility, sub_access, top_category, category_label = nil)
    if top_category == 'all_namespaces'
      api_accessibility.dig('api_namespaces', top_category, sub_access).present?
    else
      api_accessibility.dig('api_namespaces', top_category, category_label, sub_access).present?
    end
  end

  def has_no_sub_access_to_specific_category?(api_accessibility, top_category, category_label = nil)
    if top_category == 'all_namespaces'
      api_accessibility.dig('api_namespaces', top_category)&.keys.present?
    else
      api_accessibility.dig('api_namespaces', top_category, category_label)&.keys.present?
    end
  end

  def has_access_to_api_accessibility?(api_permissions, user, api_namespace)
    user_api_accessibility = user.api_accessibility['api_namespaces']

    return false unless user_api_accessibility.present?

    is_user_authorized = false

    if user_api_accessibility.keys.include?('all_namespaces')
      is_user_authorized = api_permissions.any? do |access_name|
        user_api_accessibility.dig('all_namespaces', access_name).present? && user_api_accessibility.dig('all_namespaces', access_name) == 'true'
      end
    elsif user_api_accessibility.keys.include?('namespaces_by_category')
      categories = api_namespace.categories.pluck(:label)

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
  
  def has_access_to_api_keys?(api_accessibility, access_name)
    api_accessibility.dig('api_keys', access_name).present? && api_accessibility.dig('api_keys', access_name) == 'true'
  end

  def has_only_uncategorized_access?(api_accessibility)
    api_namespaces_accessibility = api_accessibility['api_namespaces']

    return false if api_namespaces_accessibility.keys.include?('all_namespaces')

    if api_namespaces_accessibility.keys.include?('namespaces_by_category')
      categories = api_namespaces_accessibility['namespaces_by_category'].keys
      return true if categories.size == 1 && categories[0] == 'uncategorized'
    end

    false
  end

  def filter_categories_by_api_accessibility(api_accessibility, categories)
    api_namespaces_accessibility = api_accessibility['api_namespaces']

    if api_namespaces_accessibility.keys.include?('all_namespaces')
      categories
    elsif api_namespaces_accessibility.keys.include?('namespaces_by_category')
      accessible_categories = api_namespaces_accessibility['namespaces_by_category'].keys - ['uncategorized']

      categories.where(label: accessible_categories)
    end
  end
end
