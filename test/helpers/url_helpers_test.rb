require 'test_helper'

class UrlHelperTest < ActionView::TestCase
  Rails.application.routes.url_helpers

  setup do
    @public_subdomain = subdomains(:public)

  end

  test 'public tentant' do
    public_subdomain = subdomains(:public)
    Apartment::Tenant.switch(public_subdomain.name) do
      # no subdomain attached if subdomain param not passed
      refute_match 'public', root_url

      # subdomain attached if subdomain param not passed
      assert_match 'public', root_url(subdomain: 'public')
      assert_match 'restarone', root_url(subdomain: 'restarone')
    end
  end

  test 'should attach subdomain in url non public tentant' do
    restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch(restarone_subdomain) do
      assert_match restarone_subdomain, root_url
      assert_match 'public', root_url(subdomain: 'public')
    end
  end
end