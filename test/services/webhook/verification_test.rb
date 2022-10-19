require "test_helper"

class Webhook::VerificationTest  < ActiveSupport::TestCase
  setup do
    @external_api_client = external_api_clients(:webhook_drive_strategy)
    @request = ActionDispatch::Request.new({ "REQUEST_METHOD" => "POST", "HTTP_STRIPE_SIGNATURE" => "dummy_signature", "RAW_POST_DATA" => "{}" }) 
    @webhook_verification_method = WebhookVerificationMethod.create(webhook_type: 'stripe', external_api_client_id: @external_api_client.id, webhook_secret: 'secret') 
  end

  test "stripe webhook type" do
    Webhook::VerificationMethod::Stripe.any_instance.stubs(:call).returns([true, 'success'])

    verification_service = Webhook::Verification.new(@request, @webhook_verification_method)

    assert_equal @webhook_verification_method.webhook_type, verification_service.webhook_type
    assert_equal @webhook_verification_method.webhook_secret, verification_service.secret_key

    assert_equal [true, 'success'], verification_service.call
  end

  test "should return method not defined message if unlisted webhook_type is used" do
    Webhook::VerificationMethod::Stripe.any_instance.stubs(:call).returns([true, 'success'])

    verification_service = Webhook::Verification.new(@request, @webhook_verification_method)
    verification_service.webhook_type = 'random'

    assert_equal [false, 'Webhook verification method not defined'], verification_service.call
  end
end