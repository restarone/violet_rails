class ApiKey < ApplicationRecord
    before_create :set_bearer_token_if_applicable

    has_many :api_namespace_keys
    has_many :api_namespaces, through: :api_namespace_keys

    enum authentication_strategy: { bearer_token: 'bearer_token' }

    private
  
    def set_bearer_token_if_applicable
      if self.bearer_token? && bearer_token.nil?
        self.bearer_token = SecureRandom.uuid
      end
    end
end
