require 'test_helper'

class ApiAccessibilityHelperTest < ActionView::TestCase
  setup do
    @user = users(:public)
  end

  test 'should return true/false accordingly if the user has/has not some access in the provided category' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    assert has_access_to_main_category?(@user.api_accessibility, 'all_namespaces')
    refute has_access_to_main_category?(@user.api_accessibility, 'namespaces_by_category')
  end

  test 'should return true/false accordingly if the user has/has not some access in the specific category' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {test_1: {full_access: 'true'}}}})

    assert has_access_to_specific_category?(@user.api_accessibility, 'test_1')
    refute has_access_to_specific_category?(@user.api_accessibility, 'test_2')
  end

  test 'should return true/false accordingly if the user has/has not some sub-access in the specific category' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {test_1: {full_access: 'true'}}}})

    assert has_sub_access_to_specific_category?(@user.api_accessibility, 'full_access', 'namespaces_by_category', 'test_1')
    refute has_sub_access_to_specific_category?(@user.api_accessibility, 'full_access', 'namespaces_by_category', 'test_2')
  end

  test 'should return true/false accordingly if the user has no any sub-access in the specific category' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {test_1: {full_access: 'true'}, test_2: {}}}})

    assert has_no_sub_access_to_specific_category?(@user.api_accessibility, 'namespaces_by_category', 'test_1')
    refute has_no_sub_access_to_specific_category?(@user.api_accessibility, 'namespaces_by_category', 'test_2')
  end

  test 'should return true/false accordingly if the user has only uncategorized access or not' do
    @user.update(api_accessibility: {namespaces_by_category: {test_1: {full_access: 'true'}, test_2: {}}})
    refute has_only_uncategorized_access?(@user.api_accessibility)

    @user.update(api_accessibility: {namespaces_by_category: {test_1: {full_access: 'true'}, uncategorized: {full_access: 'true'}}})
    refute has_only_uncategorized_access?(@user.api_accessibility)

    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})
    refute has_only_uncategorized_access?(@user.api_accessibility)

    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {full_access: 'true'}}})
    assert has_only_uncategorized_access?(@user.api_accessibility)
  end

  test 'should return all categories if the user has access all_namespaces' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    api_namespace_1 = comfy_cms_categories(:api_namespace_1)
    api_namespace_2 = comfy_cms_categories(:api_namespace_2)
    api_namespace_3 = comfy_cms_categories(:api_namespace_3)

    filtered_categories = filter_categories_by_api_accessibility(@user.api_accessibility, Comfy::Cms::Category.of_type('ApiNamespace'))

    assert_includes filtered_categories, api_namespace_1
    assert_includes filtered_categories, api_namespace_2
    assert_includes filtered_categories, api_namespace_3
  end

  test 'should return only the categories for which the user has access to' do
    api_namespace_1 = comfy_cms_categories(:api_namespace_1)
    api_namespace_2 = comfy_cms_categories(:api_namespace_2)
    api_namespace_3 = comfy_cms_categories(:api_namespace_3)
    @user.update(api_accessibility: {namespaces_by_category: {"#{api_namespace_1.label}": {full_access: 'true'}, "#{api_namespace_2.label}": {full_access: 'true'}, uncategorized: {full_access: 'true'}}})


    filtered_categories = filter_categories_by_api_accessibility(@user.api_accessibility, Comfy::Cms::Category.of_type('ApiNamespace'))

    assert_includes filtered_categories, api_namespace_1
    assert_includes filtered_categories, api_namespace_2
    refute_includes filtered_categories, api_namespace_3
  end
end
