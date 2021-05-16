require "test_helper"

class Mailbox::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @user = User.find_by(email: 'contact@restarone.com')
    end
  end
  
  test "should not allow passthrough if not logged in" do
    get mailbox_url(subdomain: @restarone_subdomain.name)
    assert_response :redirect
  end

  test "should not allow passthrough if not allowed to manage email" do
    sign_in(@user)
    refute @user.can_manage_email
    get mailbox_url(subdomain: @restarone_subdomain.name)
    assert_response :redirect
  end

  test "should allow passthrough if allowed to manage email" do
    sign_in(@user)
    @user.update(can_manage_email: true)
    get mailbox_url(subdomain: @restarone_subdomain.name)
    assert_response :success
    assert_template :show
  end
end
