module Webhook
  class Verification
    attr_accessor :request, :verification_method

    def initialize(request, verification_method)
      @request = request
      @verification_method = verification_method
    end

    def call
      case @verification_method.webhook_type

      when WebhookVerificationMethod.webhook_types[:stripe]
        Webhook::VerificationMethod::Stripe.new(request, @verification_method.webhook_secret).call
      when WebhookVerificationMethod.webhook_types[:custom]
        Webhook::VerificationMethod::Custom.new(request, @verification_method).call
      else
        [false, 'Webhook verification method not defined']
      end
    end
  end
end
