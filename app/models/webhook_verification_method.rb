class WebhookVerificationMethod < ApplicationRecord
  include Encryptable

  attr_encrypted :webhook_secret

  belongs_to :external_api_client

  validates :custom_method_definition, safe_executable: true

  enum webhook_type: {
    stripe: 'stripe',
    custom: 'custom'
  }
end
