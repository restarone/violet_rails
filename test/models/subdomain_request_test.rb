require "test_helper"

class SubdomainRequestTest < ActiveSupport::TestCase
  setup do
    @subdomain = Subdomain.first
  end

  test 'can be created' do
    subdomain_request = SubdomainRequest.new(
      subdomain_name: 'great-domain-name',
      email: 'test@testingsystem.com',
    )
    assert subdomain_request.save
  end

  test "validates against existing subdomains" do
    refute SubdomainRequest.new(subdomain_name: @subdomain.name).valid?
  end

  test "validates against subdomain class validations" do
    refute SubdomainRequest.new(subdomain_name: 'mmw.').valid?
  end

  test "validates email" do
    subdomain_request = SubdomainRequest.new(
      subdomain_name: 'great-domain-name',
      email: 'testtestingsystemcom',
    )
    refute subdomain_request.save
  end

  test 'allows incremental build' do
    subdomain_request = SubdomainRequest.new
    assert subdomain_request.save
  end
end
