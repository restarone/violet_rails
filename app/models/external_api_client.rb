class ExternalApiClient < ApplicationRecord
  extend FriendlyId
  friendly_id :label, use: :slugged
  belongs_to :api_namespace
end
