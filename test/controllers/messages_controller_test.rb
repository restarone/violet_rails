require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @message = messages(:one)
    skip
  end

  test "should get index" do
    get messages_url(subdomain: 'restarone')
    assert_response :success
  end

  test "should get new" do
    get new_message_url(subdomain: 'restarone')
    assert_response :success
  end

  test "should create message" do
    assert_difference('Message.all.reload.size') do
      post messages_url(subdomain: 'restarone'), params: { message: { title: @message.title } }
    end

    assert_redirected_to message_url(Message.last)
  end

  test "should show message" do
    get message_url(id: @message.id, subdomain: 'restarone')
    assert_response :success
  end

  test "should get edit" do
    get edit_message_url(@message.id, subdomain: 'restarone')
    assert_response :success
  end

  test "should update message" do
    patch message_url(id: @message), params: { message: { title: @message.title } }
    assert_redirected_to message_url(@message)
  end

  test "should destroy message" do
    assert_difference('Message.count', -1) do
      delete message_url(id: @message.id, subdomain: 'restarone')
    end

    assert_redirected_to messages_url
  end
end
