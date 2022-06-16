require "test_helper"

class EMailerTest < ActionMailer::TestCase
  test 'sends email to multiple recipients' do
    recipients = ['a@a.com', 'b@b.com', 'c@c.com']

    message_thread = MessageThread.new(recipients: recipients)
    message = Message.new(content: 'content')
    email = EMailer.with(message: message, message_thread: message_thread).ship

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal recipients, email.to
  end
end
