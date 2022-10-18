
module Webhook
  class Verification
    attr_accessor :request, :webhook_type, :secret_key

    def initialize(request, verification_method)
      @request = request
      @webhook_type = verification_method.webhook_type
      @secret_key = verification_method.webhook_secret
    end

    def call
      case webhook_type

      when WebhookVerificationMethod.webhook_types[:stripe]
        Webhook::VerificationMethod::Stripe.new(request, secret_key).call
      else
        [false, 'Webhook verification method not defined']
      end
    end
  end
end
