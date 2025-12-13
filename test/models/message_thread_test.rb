require "test_helper"

class MessageThreadTest < ActiveSupport::TestCase
  def setup
    @message_thread = MessageThread.new(
      recipients: ["test@example.com"],
      subject: "Test Subject"
    )
  end

  test "should be valid with recipients" do
    assert @message_thread.valid?
  end

  test "should validate presence of recipients" do
    @message_thread.recipients = nil
    assert_not @message_thread.valid?
    assert_includes @message_thread.errors[:recipients], "can't be blank"
  end

  test "should validate recipients length minimum" do
    @message_thread.recipients = []
    assert_not @message_thread.valid?
    assert_includes @message_thread.errors[:recipients], "is too short (minimum is 1 character)"
  end

  test "should have many messages" do
    assert_respond_to @message_thread, :messages
    assert_respond_to @message_thread, :messages=
  end

  test "should accept nested attributes for messages" do
    assert_respond_to @message_thread, :messages_attributes=
  end

  test "should include comfy cms with categories" do
    assert_includes MessageThread.included_modules, Comfy::Cms::WithCategories
  end

  test "should have search scope" do
    assert_respond_to MessageThread, :search_messages_content_body_or_subject_or_messages_from_or_recipients_contains
  end

  test "should have ransackable scopes" do
    ransackable_scopes = MessageThread.ransackable_scopes
    assert_includes ransackable_scopes, :search_messages_content_body_or_subject_or_messages_from_or_recipients_contains
  end
end
