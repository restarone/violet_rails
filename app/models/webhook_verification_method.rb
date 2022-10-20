class WebhookVerificationMethod < ApplicationRecord
  include Encryptable

  attr_encrypted :webhook_secret

  belongs_to :external_api_client

  enum webhook_type: {
    stripe: 'stripe'
  }
end
