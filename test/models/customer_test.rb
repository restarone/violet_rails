require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  setup do
    @customer = customers(:public)
  end

  test "initializes only if subdomain name is safe" do
    refute Customer.new(
      subdomain: '.voo.',
      email: 'foo@bar.com',
      password: '123456',
      password_confirmation: '123456'
    ).valid?
    refute Customer.new(
      subdomain: @customer.subdomain,
      email: 'foo@bar.com',
      password: '123456',
      password_confirmation: '123456'
    ).valid?
    
  end
end
