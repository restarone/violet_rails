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

  test "can be destroyed" do
    customer = Customer.new(
      email: 'foo@bar.com',
      password: '123456',
      password_confirmation: '123456',
      subdomain: 'foo'
    )
    assert customer.save
    customer.destroy
  end

  test "can have many subdomains" do
    assert @customer.subdomains.any?
  end

  test 'cannot be cloned more than once' do
    user = User.create_clone_for(@customer)
    assert user
    assert_equal user.email, @customer.email
    assert_equal user.encrypted_password, @customer.encrypted_password
    begin
      User.create_clone_for(@customer)
    rescue ActiveRecord::RecordNotUnique => e
        # yay db unique constraint works
    end
  end
end
