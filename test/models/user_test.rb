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

  test "can be destroyed if not last user or admin" do
    user = User.new(
      email: 'foo@bar.com',
      password: '123456',
      password_confirmation: '123456',
    )
    user.save
    assert user.destroy
  end

  test "cannot be destroyed if last user" do
    User.delete_all
    user = User.new(
      email: 'foo@bar.com',
      password: '123456',
      password_confirmation: '123456',
    )
    user.save
    assert_not user.destroy
  end

  test "cannot be destroyed if last admin" do
    User.delete_all
    user = User.new(
      email: 'foo@bar.com',
      password: '123456',
      password_confirmation: '123456',
    )
    admin = User.new(
      email: 'admin@email.com',
      password: '123456',
      password_confirmation: '123456',
      can_manage_users: true
    )
    user.save
    admin.save
    assert_not admin.destroy
  end

  test "can infer session timeout time (default)" do
    assert_equal @user.timeout_in, eval(User::SESSION_TIMEOUT[0][:exec])
  end
end
