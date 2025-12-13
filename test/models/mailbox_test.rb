require "test_helper"

class MailboxTest < ActiveSupport::TestCase
  def setup
    @mailbox = Mailbox.new
  end

  test "should be valid" do
    assert @mailbox.valid?
  end

  test "should inherit from ApplicationRecord" do
    assert_kind_of ApplicationRecord, @mailbox
  end
end
