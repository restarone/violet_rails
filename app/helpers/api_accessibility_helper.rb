module ApiAccessibilityHelper
  def has_access_to_main_category?(api_accessibility, top_category)
    api_accessibility.dig(top_category).present?
  end

  def has_access_to_specific_category?(api_accessibility, category_label)
    api_accessibility.dig('namespaces_by_category', category_label).present?
  end

  def has_sub_access_to_specific_category?(api_accessibility, sub_access, top_category, category_label = nil)
    if top_category == 'all_namespaces'
      api_accessibility.dig(top_category, sub_access).present?
    else
      api_accessibility.dig(top_category, category_label, sub_access).present?
    end
  end

  def has_no_sub_access_to_specific_category?(api_accessibility, top_category, category_label = nil)
    if top_category == 'all_namespaces'
      api_accessibility.dig(top_category)&.keys.present?
    else
      api_accessibility.dig(top_category, category_label)&.keys.present?
    end
  end
end
