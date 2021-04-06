require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  setup do
    @customer = customers(:public)
  end

  test "can be initialized" do
    assert Customer.new(
      email: 'foo@bar.com',
      password: '123456',
      password_confirmation: '123456'
    ).valid?
    refute Customer.new(
      email: @customer.email,
      password: '123456',
      password_confirmation: '123456'
    ).valid?
  end

  test "can have many subdomains" do
    assert @customer.subdomains.any?
  end
end
