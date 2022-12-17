require 'test_helper'

class ApiAccessibilityHelperTest < ActionView::TestCase
  setup do
    @user = users(:public)
  end

  test 'should return true/false accordingly if the user has/has not some access in the provided category' do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    assert has_access_to_main_category?(@user.api_accessibility, 'all_namespaces')
    refute has_access_to_main_category?(@user.api_accessibility, 'namespaces_by_category')
  end

  test 'should return true/false accordingly if the user has/has not some access in the specific category' do
    @user.update(api_accessibility: {namespaces_by_category: {test_1: {full_access: 'true'}}})

    assert has_access_to_specific_category?(@user.api_accessibility, 'test_1')
    refute has_access_to_specific_category?(@user.api_accessibility, 'test_2')
  end

  test 'should return true/false accordingly if the user has/has not some sub-access in the specific category' do
    @user.update(api_accessibility: {namespaces_by_category: {test_1: {full_access: 'true'}}})

    assert has_sub_access_to_specific_category?(@user.api_accessibility, 'full_access', 'namespaces_by_category', 'test_1')
    refute has_sub_access_to_specific_category?(@user.api_accessibility, 'full_access', 'namespaces_by_category', 'test_2')
  end

  test 'should return true/false accordingly if the user has no any sub-access in the specific category' do
    @user.update(api_accessibility: {namespaces_by_category: {test_1: {full_access: 'true'}, test_2: {}}})

    assert has_no_sub_access_to_specific_category?(@user.api_accessibility, 'namespaces_by_category', 'test_1')
    refute has_no_sub_access_to_specific_category?(@user.api_accessibility, 'namespaces_by_category', 'test_2')
  end
end
