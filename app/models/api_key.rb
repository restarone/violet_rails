class ApiKey < ApplicationRecord
  include Encryptable
  extend FriendlyId

  friendly_id :label, use: :slugged

  attr_encrypted :token

  before_create :set_encrypted_token_if_applicable

  has_many :api_namespace_keys, dependent: :destroy
  accepts_nested_attributes_for :api_namespace_keys

  has_many :api_namespaces, through: :api_namespace_keys

  enum authentication_strategy: { bearer_token: 'bearer_token' }

  private

  def set_encrypted_token_if_applicable
    if self.bearer_token? && token.nil?
      self.token = SecureRandom.uuid
    end
  end
end
