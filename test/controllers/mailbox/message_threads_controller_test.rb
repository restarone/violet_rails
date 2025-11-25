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

  test 'viewing unread thread sets unread:true' do
    # todo test https://github.com/restarone/violet_rails/blob/9476c661537a1688a81c95802d5f49a6617f0678/app/controllers/mailbox/message_threads_controller.rb
  end

  test 'renders email content with style tags properly' do
    sign_in(@user)
    
    # Create a message with HTML content including meta, style, and title tags (like Revolvapp templates)
    html_content = <<~HTML
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
      <title>My Email</title>
      <style type="text/css">
        .test-class { color: red; }
      </style>
      <div class="test-class">Test content</div>
    HTML
    
    Apartment::Tenant.switch @subdomain.name do
      message_thread = MessageThread.create!(
        unread: true, 
        subject: 'Test Email with Styles', 
        recipients: [@user.email]
      )
      message = message_thread.messages.create!(content: html_content)
      
      get mailbox_message_thread_url(subdomain: @subdomain.name, id: message_thread.id)
      assert_response :success
      
      # Extract the message content area from the response
      # The message content is rendered in a div with class 'card-text bg-light px-2 py-3'
      message_content_match = response.body.match(/<div class='card-text bg-light px-2 py-3'>(.*?)<\/div>/m)
      assert message_content_match, "Could not find message content in response"
      message_content = message_content_match[1]
      
      # Verify that meta, style, title tags are NOT present in the message content
      refute_match(/<meta/, message_content, "Meta tags should be removed from message content")
      refute_match(/<style/, message_content, "Style tags should be removed from message content")
      refute_match(/<title/, message_content, "Title tags should be removed from message content")
      
      # Verify that the actual content IS present
      assert_match(/Test content/, message_content, "Message content should be present")
      
      # Verify that style tag content is not displayed as text
      refute_match(/\.test-class \{ color: red; \}/, message_content, "CSS code should not be visible as text")
    end
  end
end
