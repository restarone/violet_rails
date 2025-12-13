require "test_helper"

class MessageTest < ActiveSupport::TestCase
  def setup
    @message_thread = message_threads(:one)
    @message = Message.new(
      content: "Test message content",
      message_thread: @message_thread
    )
  end

  test "should be valid with content and message_thread" do
    assert @message.valid?
  end

  test "should validate presence of content" do
    @message.content = nil
    assert_not @message.valid?
    assert_includes @message.errors[:content], "can't be blank"
  end

  test "should belong to message_thread" do
    assert_respond_to @message, :message_thread
    assert_equal @message_thread, @message.message_thread
  end

  test "should have rich text content" do
    assert_respond_to @message, :content
    assert_respond_to @message, :rich_text_content
  end

  test "should have attachments" do
    assert_respond_to @message, :attachments
  end

  test "should generate email_message_id before save" do
    @message.save!
    assert_not_nil @message.email_message_id
    assert_match /.+@.+/, @message.email_message_id
  end

  test "should update message_thread current_email_message_id after create" do
    original_message_id = @message_thread.current_email_message_id
    @message.save!
    @message_thread.reload
    assert_equal @message.email_message_id, @message_thread.current_email_message_id
    assert_not_equal original_message_id, @message_thread.current_email_message_id
  end

  test "should default order by created_at DESC" do
    @message.save!
    older_message = Message.create!(content: "Older message", message_thread: @message_thread)
    newer_message = Message.create!(content: "Newer message", message_thread: @message_thread)
    
    messages = Message.all
    assert_equal newer_message, messages.first
    assert_equal older_message, messages.second
  end
end
