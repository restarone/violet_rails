require "test_helper"

class Mailbox::MessageThreadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_email: true)
    @message_thread = message_threads(:public)
    @subdomain = subdomains(:public)
    @message_thread = MessageThread.last
    @subdomain.initialize_mailbox
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
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

  test "tracks message view (if tracking is enabled and cookies accepted)" do
    @restarone_subdomain.update(tracking_enabled: true)
    @restarone_subdomain.initialize_mailbox

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_message_thread = MessageThread.create!(unread: true, subject: 'foo', recipients: [@unauthorized_user.email])

      @unauthorized_user.update(can_access_admin: true)
      sign_in(@unauthorized_user)

      assert_difference "Ahoy::Event.count", +1 do
        get mailbox_message_thread_url(subdomain: @restarone_subdomain.name, id: @unauthorized_user.id), headers: {"HTTP_COOKIE" => "cookies_accepted=true;"}
        assert_response :success
      end

    end
  end

  test "does not track message view (if tracking is disabled)" do
    @restarone_subdomain.update(tracking_enabled: false)
    @restarone_subdomain.initialize_mailbox

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_message_thread = MessageThread.create!(unread: true, subject: 'foo', recipients: [@unauthorized_user.email])

      @unauthorized_user.update(can_access_admin: true)
      sign_in(@unauthorized_user)

      assert_no_difference "Ahoy::Event.count", +1 do
        get mailbox_message_thread_url(subdomain: @restarone_subdomain.name, id: @unauthorized_user.id)
        assert_response :success
      end

    end
  end

  test "does not track message view (if tracking is disabled but cookies accepted)" do
    @restarone_subdomain.update(tracking_enabled: false)
    @restarone_subdomain.initialize_mailbox

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_message_thread = MessageThread.create!(unread: true, subject: 'foo', recipients: [@unauthorized_user.email])

      @unauthorized_user.update(can_access_admin: true)
      sign_in(@unauthorized_user)

      assert_no_difference "Ahoy::Event.count", +1 do
        get mailbox_message_thread_url(subdomain: @restarone_subdomain.name, id: @unauthorized_user.id), headers: {"HTTP_COOKIE" => "cookies_accepted=true;"}
        assert_response :success
      end

    end
  end

  test "does not track message view (if tracking is enabled but cookies rejected)" do
    @restarone_subdomain.update(tracking_enabled: true)
    @restarone_subdomain.initialize_mailbox

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_message_thread = MessageThread.create!(unread: true, subject: 'foo', recipients: [@unauthorized_user.email])

      @unauthorized_user.update(can_access_admin: true)
      sign_in(@unauthorized_user)

      assert_no_difference "Ahoy::Event.count", +1 do
        get mailbox_message_thread_url(subdomain: @restarone_subdomain.name, id: @unauthorized_user.id), headers: {"HTTP_COOKIE" => "cookies_accepted=false;"}
        assert_response :success
      end

    end
  end

  test "does not track message view (if tracking is enabled but cookies not consented)" do
    @restarone_subdomain.update(tracking_enabled: true)
    @restarone_subdomain.initialize_mailbox

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_message_thread = MessageThread.create!(unread: true, subject: 'foo', recipients: [@unauthorized_user.email])

      @unauthorized_user.update(can_access_admin: true)
      sign_in(@unauthorized_user)

      assert_no_difference "Ahoy::Event.count", +1 do
        get mailbox_message_thread_url(subdomain: @restarone_subdomain.name, id: @unauthorized_user.id)
        assert_response :success
      end

    end
  end

  test 'renders #new' do
    sign_in(@user)
    get new_mailbox_message_thread_url(subdomain: @subdomain.name)
    assert_response :success
  end

  test '#create' do
    sign_in(@user)
    payload = {
      message_thread: {
        recipients: ['contact@restarone.com'],
        message: {
          content: 'foo'
        }
      }
    }
    Apartment::Tenant.switch @subdomain.name do
      perform_enqueued_jobs do
        assert_difference "MessageThread.all.size", +1 do
          assert_difference "Message.all.size", +1 do
            post mailbox_message_threads_url(subdomain: @subdomain.name), params: payload
            assert_redirected_to mailbox_message_thread_url(subdomain: @subdomain.name, id: MessageThread.last.id)
            assert flash.notice
            refute Message.last.from
          end
        end
      end
    end
  end

  test '#create (www)' do
    sign_in(@user)
    payload = {
      message_thread: {
        recipients: ['contact@restarone.com'],
        message: {
          content: 'foo'
        }
      }
    }
    perform_enqueued_jobs do
      assert_difference "MessageThread.all.size", +1 do
        assert_difference "Message.all.size", +1 do
          post mailbox_message_threads_url(subdomain: 'www'), params: payload
          assert_redirected_to mailbox_message_thread_url(subdomain: 'www', id: MessageThread.last.id)
          assert flash.notice
          refute Message.last.from
        end
      end
    end
  end

  test '#send_message' do
    sign_in(@user)
    payload = {
      message_thread: {
        message: {
          content: 'foo'
        }
      }
    }
    Apartment::Tenant.switch @subdomain.name do
      perform_enqueued_jobs do
        assert_no_difference "MessageThread.all.size" do
          assert_difference "Message.all.size", +1 do
            post send_message_mailbox_message_thread_url(subdomain: @subdomain.name, id: @message_thread.id), params: payload
            assert_redirected_to mailbox_message_thread_url(subdomain: @subdomain.name, id: @message_thread.id)
            assert flash.notice
            refute Message.last.from
          end
        end
      end
    end
  end

  test '#send_message (www)' do
    sign_in(@user)
    payload = {
      message_thread: {
        message: {
          content: 'foo'
        }
      }
    }

    perform_enqueued_jobs do
      assert_no_difference "MessageThread.all.size" do
        assert_difference "Message.all.size", +1 do
          post send_message_mailbox_message_thread_url(subdomain: 'www', id: @message_thread.id), params: payload
          assert_redirected_to mailbox_message_thread_url(subdomain: 'www', id: @message_thread.id)
          assert flash.notice
          refute Message.last.from
        end
      end
    end
  end
end
