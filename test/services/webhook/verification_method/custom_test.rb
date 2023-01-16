require "test_helper"

class Webhook::VerificationMethod::StripeTest < ActiveSupport::TestCase
  setup do
    @external_api_client = external_api_clients(:webhook_drive_strategy)
    @request = ActionDispatch::Request.new({ "REQUEST_METHOD" => "POST", "HTTP_STRIPE_SIGNATURE" => "dummy_signature", "RAW_POST_DATA" => "{}" }) 
    @webhook_verification_method = WebhookVerificationMethod.create(
      webhook_type: 'custom',
      external_api_client_id: @external_api_client.id,
      webhook_secret: 'secret',
      custom_method_definition: "
      if request.headers['Authorization'] == verification_method.webhook_secret
        [true, 'Verification Success']
      else
        [false, 'Invalid Authorization Token']
      end"
    ) 
  end

  test '#call: should return success' do
    @request.headers["Authorization"] = 'secret'

    response = Webhook::VerificationMethod::Custom.new(@request, @webhook_verification_method).call

    assert_equal([true, 'Verification Success'], response)
  end

  test '#call: should return error message' do
    @request.headers["Authorization"] = 'not secret'

    response = Webhook::VerificationMethod::Custom.new(@request, @webhook_verification_method).call

    assert_equal([false, 'Invalid Authorization Token'], response)
  end
end