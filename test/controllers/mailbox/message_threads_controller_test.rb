require "test_helper"

class Mailbox::MessageThreadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_email: true)
    @message_thread = message_threads(:public)
    @subdomain = subdomains(:public)
    @subdomain.initialize_mailbox
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      @unauthorized_user = User.first
      @unauthorized_user.update(can_manage_email: true)
    end
  end

  test "denies #show if not logged in" do
    get mailbox_message_thread_url(subdomain: @subdomain.name, id: @message_thread.id)
    assert_response :redirect
    assert_redirected_to new_user_session_url(subdomain: @subdomain.name)
  end

  test "denies #show if user doesnt belong to subdomain" do
    sign_in(@unauthorized_user)
    get mailbox_message_thread_url(subdomain: @subdomain.name, id: @message_thread.id)
    assert_response :redirect
    assert flash.alert
    assert_redirected_to root_url
  end

  test "allows #show if logged in" do
    sign_in(@user)
    get mailbox_message_thread_url(subdomain: @subdomain.name, id: @message_thread.id)
    assert_response :success
  end

  test 'renders #new' do
    sign_in(@user)
    get new_mailbox_message_thread_url(subdomain: @subdomain.name)
    assert_response :success
  end

  test '#create' do
    payload = {
      message_thread: {
        recipient: 'contact@restarone.com',
        message: {
          content: 'foo'
        }
      }
    }
  end
end
