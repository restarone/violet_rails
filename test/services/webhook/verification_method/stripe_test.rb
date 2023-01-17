require "test_helper"

class Webhook::VerificationMethod::StripeTest < ActiveSupport::TestCase
  setup do
    @request = ActionDispatch::Request.new({ "REQUEST_METHOD" => "POST", "HTTP_STRIPE_SIGNATURE" => "dummy_signature", "RAW_POST_DATA" => "{}" })  
  end

  test '#call: should return success message if stripe verifies signature' do
    ::Stripe::Webhook.expects(:construct_event).returns({})

    response = Webhook::VerificationMethod::Stripe.new(@request, 'dummy_signing_secret').call

    assert_equal([true, 'Signature Verified'], response)
  end

  test '#call: should return json parse error message if stripe raise JSON::ParserError' do
    ::Stripe::Webhook.expects(:construct_event).raises(JSON::ParserError)

    response = Webhook::VerificationMethod::Stripe.new(@request, 'dummy_signing_secret').call

    assert_equal([false, "Invalid json payload"], response)
  end

  test '#call: should return signature verification error message if stripe raises Stripe::SignatureVerificationError' do
    Stripe::Webhook.expects(:construct_event).raises(::Stripe::SignatureVerificationError.new('msg', 'sig_header'))

    response = Webhook::VerificationMethod::Stripe.new(@request, 'dummy_signing_secret').call

    assert_equal([false, 'Signature verification failed'], response)
  end
end