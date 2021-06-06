require "test_helper"

class Mailbox::MailboxControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_email: true)
    @subdomain = subdomains(:public)
    @subdomain.initialize_mailbox
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
  end

  test "denies #show if not logged in" do
    get mailbox_url(subdomain: @subdomain.name)
    assert_response :redirect
    assert_redirected_to new_user_session_url(subdomain: @subdomain.name)
  end

  test "denies #show if user doesnt belong to subdomain" do
    sign_in(@user)
    get mailbox_url(subdomain: @restarone_subdomain)
    assert_response :redirect
    assert flash.alert
    assert_redirected_to root_url
  end

  test "denies #show if user cant manage email" do
    sign_in(@user)
    @user.update(can_manage_email: false)
    get mailbox_url
    assert_response :redirect
    assert flash.alert
    assert_redirected_to root_url
  end

  test "allows #show if logged in" do
    sign_in(@user)
    get mailbox_url(subdomain: @subdomain.name)
    assert_response :success
  end

  test "allows #show if logged in (root)" do
    sign_in(@user)
    get mailbox_url
    assert_response :success
  end
end
