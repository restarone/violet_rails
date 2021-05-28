require "test_helper"

class SubdomainRequestTest < ActiveSupport::TestCase
  setup do
    @subdomain = Subdomain.first
    @user = User.first
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

  test 'runs validations before approval' do
    subdomain_request = SubdomainRequest.new
    assert subdomain_request.save
    subdomain_request.update(approved: true)
  end

  test 'after email is set sends email to global admin' do
    assert @user.update(global_admin: true)
    recipients = User.where(global_admin: true)
    subdomain_request = SubdomainRequest.new(subdomain_name: 'great-domain-name')
    subdomain_request.save
    assert_changes "UserMailer.deliveries.size" do
      perform_enqueued_jobs do
        subdomain_request.update(email: 'test@testingsystem.com')
      end
    end
  end
end
