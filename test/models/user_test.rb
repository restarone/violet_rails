require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:public)
  end

  test "can be initialized" do
    assert User.new(
      email: 'foo@bar.com',
      password: '123456',
      password_confirmation: '123456'
    ).valid?
    refute User.new(
      email: @user.email,
      password: '123456',
      password_confirmation: '123456'
    ).valid?
  end

  test "can be destroyed" do
    user = User.new(
      email: 'foo@bar.com',
      password: '123456',
      password_confirmation: '123456',
    )
    assert user.save
    user.destroy
  end
end
