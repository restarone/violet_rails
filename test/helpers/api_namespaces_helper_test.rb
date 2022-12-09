require 'test_helper'

class ApiNamespacesHelperTest < ActionView::TestCase
  test 'should use slug of api_namespace to contruct the url instead of using name' do
    namespace = api_namespaces(:namespace_with_slash)
    assert_includes(api_base_url(Subdomain.current, namespace), namespace.slug)
    refute_includes(api_base_url(Subdomain.current, namespace), namespace.name)
  end
end