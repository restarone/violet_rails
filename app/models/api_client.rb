class ApiClient < ApplicationRecord
  extend FriendlyId
  friendly_id :label, use: :slugged
  belongs_to :api_namespace

  AUTHENTICATION_STRATEGIES = {
    bearer_token: 'bearer token'
  } 
    
  validates :authentication_strategy, inclusion: { in: ApiClient::AUTHENTICATION_STRATEGIES.keys.map{ |n| n.to_s }  }

  before_create :set_bearer_token_if_applicable

  private

  def set_bearer_token_if_applicable
    if self.authentication_strategy == AUTHENTICATION_STRATEGIES.keys[0].to_s
      self.bearer_token = SecureRandom.uuid
    end
  end
end
