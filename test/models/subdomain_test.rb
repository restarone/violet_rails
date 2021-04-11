require "test_helper"

class SubdomainTest < ActiveSupport::TestCase
  setup do
    @subdomain = subdomains(:public)
  end

  test "uniqness" do
    duplicate = Subdomain.new(
      name: @subdomain.name
    )
    refute duplicate.valid?
  end

  test 'full host' do
    assert @subdomain.hostname
  end
end
