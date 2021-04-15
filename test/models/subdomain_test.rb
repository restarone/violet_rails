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

  test 'downcases name' do
    name = 'Capitalized'
    subdomain = Subdomain.new(
      name: name
    )
    assert subdomain.valid?
    subdomain.save
    assert_equal name.downcase, subdomain.name
  end

  test 'sums storage usage' do
    assert @subdomain.storage_used < Subdomain::MAXIMUM_STORAGED_ALLOWANCE
  end
end
