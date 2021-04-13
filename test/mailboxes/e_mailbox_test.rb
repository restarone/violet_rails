require "test_helper"

class EMailboxTest < ActionMailbox::TestCase
  test "inbound mail routes to correct schema" do
    receive_inbound_email_from_mail \
      to: '"Don Restarone" <restarone@restarone.solutions>',
      from: '"else" <else@example.com>',
      subject: "Hello world!",
      body: "Hello?"
  end
end
