require "test_helper"

class Webhook::VerificationTest  < ActiveSupport::TestCase
  setup do
    @external_api_client = external_api_clients(:webhook_drive_strategy)
    @request = ActionDispatch::Request.new({ "REQUEST_METHOD" => "POST", "HTTP_STRIPE_SIGNATURE" => "dummy_signature", "RAW_POST_DATA" => "{}" }) 
  end

  test "stripe webhook type" do
    Webhook::VerificationMethod::Stripe.any_instance.stubs(:call).returns([true, 'success'])
    webhook_verification_method = WebhookVerificationMethod.create(webhook_type: 'stripe', external_api_client_id: @external_api_client.id, webhook_secret: 'secret') 

    verification_service = Webhook::Verification.new(@request, webhook_verification_method)

    assert_equal webhook_verification_method, verification_service.verification_method
    assert_equal @request, verification_service.request

    assert_equal [true, 'success'], verification_service.call
  end

  test "custom webhook type" do
    Webhook::VerificationMethod::Custom.any_instance.stubs(:call).returns([true, 'success'])
    webhook_verification_method = WebhookVerificationMethod.create(webhook_type: 'custom', external_api_client_id: @external_api_client.id, webhook_secret: 'secret') 

    verification_service = Webhook::Verification.new(@request, webhook_verification_method)

    assert_equal webhook_verification_method, verification_service.verification_method
    assert_equal @request, verification_service.request

    assert_equal [true, 'success'], verification_service.call
  end
end