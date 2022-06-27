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

  test "#show: searches email-threads by email-body content" do
    other_user = users(:one)

    message_thread_1 = MessageThread.first
    message_1 = message_thread_1.messages.create!(content: '<div>body 1</div>')

    message_thread_2 = MessageThread.create!(unread: true, subject: 'test', recipients: [other_user.email])
    message_2 = message_thread_2.messages.create!(content: '<div>body 2</div>')

    message_thread_3 = MessageThread.create!(unread: true, subject: 'new email', recipients: [other_user.email])
    message_3 = message_thread_3.messages.create!(content: '<div>description</div>')

    message_thread_4 = MessageThread.create!(unread: true, subject: 'restarone', recipients: [other_user.email])
    message_4 = message_thread_4.messages.create!(content: '<div>violet</div>')

    payload = {
      q: {
        search_messages_content_body_or_subject_or_messages_from_or_recipients_contains: 'body'
      }
    }
    
    sign_in(@user)
    get mailbox_url, params: payload

    assert_response :success
    
    message_threads = @controller.view_assigns['message_threads']

    assert_equal [message_thread_1.id, message_thread_2.id].sort, message_threads.pluck(:id).sort
    
    message_threads.each do |message_thread|
      assert_match 'body', message_thread.messages.first.content.body.to_s
    end
  end

  test "#show: searches email-threads by email-subject" do
    other_user = users(:one)

    message_thread_1 = MessageThread.first
    message_1 = message_thread_1.messages.create!(content: '<div>body 1</div>')

    message_thread_2 = MessageThread.create!(unread: true, subject: 'test', recipients: [other_user.email])
    message_2 = message_thread_2.messages.create!(content: '<div>body 2</div>')

    message_thread_3 = MessageThread.create!(unread: true, subject: 'new email', recipients: [other_user.email])
    message_3 = message_thread_3.messages.create!(content: '<div>description</div>')

    message_thread_4 = MessageThread.create!(unread: true, subject: 'restarone inc', recipients: [other_user.email])
    message_4 = message_thread_4.messages.create!(content: '<div>violet</div>')

    payload = {
      q: {
        search_messages_content_body_or_subject_or_messages_from_or_recipients_contains: 'restarone inc'
      }
    }
    
    sign_in(@user)
    get mailbox_url, params: payload

    assert_response :success
    
    message_threads = @controller.view_assigns['message_threads']

    assert_equal [message_thread_4.id].sort, message_threads.pluck(:id).sort
    
    message_threads.each do |message_thread|
      assert_match 'restarone', message_thread.subject
    end
  end

  test "#show: searches email-threads by sender-email-address" do
    other_user = users(:one)

    message_thread_1 = MessageThread.first
    message_1 = message_thread_1.messages.create!(content: '<div>body 1</div>')

    message_thread_2 = MessageThread.create!(unread: true, subject: 'test', recipients: [other_user.email])
    message_2 = message_thread_2.messages.create!(content: '<div>body 2</div>')

    message_thread_3 = MessageThread.create!(unread: true, subject: 'new email', recipients: [other_user.email])
    message_3 = message_thread_3.messages.create!(content: '<div>description</div>', from: 'violet@rails.com')

    message_thread_4 = MessageThread.create!(unread: true, subject: 'restarone', recipients: [other_user.email])
    message_4 = message_thread_4.messages.create!(content: '<div>violet</div>', from: 'violet@rails.com')

    payload = {
      q: {
        search_messages_content_body_or_subject_or_messages_from_or_recipients_contains: 'violet@rails.com'
      }
    }
    
    sign_in(@user)
    get mailbox_url, params: payload

    assert_response :success
    
    message_threads = @controller.view_assigns['message_threads']

    assert_equal [message_thread_3.id, message_thread_4.id].sort, message_threads.pluck(:id).sort
    
    message_threads.each do |message_thread|
      assert_match 'violet@rails.com', message_thread.messages.first.from
    end
  end

  test "#show: searches email-threads by recipients-email-address" do
    other_user = users(:one)

    message_thread_1 = MessageThread.first
    message_1 = message_thread_1.messages.create!(content: '<div>body 1</div>')

    message_thread_2 = MessageThread.create!(unread: true, subject: 'test', recipients: [other_user.email])
    message_2 = message_thread_2.messages.create!(content: '<div>body 2</div>')

    message_thread_3 = MessageThread.create!(unread: true, subject: 'new email', recipients: [other_user.email])
    message_3 = message_thread_3.messages.create!(content: '<div>description</div>', from: 'violet@rails.com')

    message_thread_4 = MessageThread.create!(unread: true, subject: 'restarone', recipients: [other_user.email])
    message_4 = message_thread_4.messages.create!(content: '<div>violet</div>', from: 'violet@rails.com')

    payload = {
      q: {
        search_messages_content_body_or_subject_or_messages_from_or_recipients_contains: other_user.email
      }
    }
    
    sign_in(@user)
    get mailbox_url, params: payload

    assert_response :success
    
    message_threads = @controller.view_assigns['message_threads']

    assert_equal [message_thread_2.id, message_thread_3.id, message_thread_4.id].sort, message_threads.pluck(:id).sort
    
    message_threads.each do |message_thread|
      assert_match other_user.email, message_thread.recipients.to_s
    end
  end
end
