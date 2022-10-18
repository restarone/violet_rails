require 'stripe'
module Webhook
  module VerificationMethod
    class Stripe
      attr_accessor :signature, :payload, :endpoint_secret

      def initialize(request, endpoint_secret)
        @signature = request.env['HTTP_STRIPE_SIGNATURE']
        @payload = request.body.read
        @endpoint_secret = endpoint_secret
      end

      def call
        begin
          ::Stripe::Webhook.construct_event(
            payload, signature, endpoint_secret
          )
        rescue JSON::ParserError => e
          # Invalid payload
          return [false, 'Invalid json payload']
        rescue ::Stripe::SignatureVerificationError => e
          # Invalid signature
          return [false, 'Signature verification failed']
        end
        return [true, 'Signature Verified']
      end
    end
  end
end


