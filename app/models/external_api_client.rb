class ExternalApiClient < ApplicationRecord
  STATUSES = {
    stopped: 'Stopped',
    running: 'Running',
    error: 'Error',
    sleeping: 'Sleeping'
  }

  DRIVE_STRATEGIES = {
    on_demand: 'On Demand',
    cron: 'Cron'
  }
  extend FriendlyId
  friendly_id :label, use: :slugged
  belongs_to :api_namespace

  validates :status, inclusion: { in: ExternalApiClient::STATUSES.keys.map(&:to_s)  }
  validates :drive_strategy, inclusion: { in: ExternalApiClient::DRIVE_STRATEGIES.keys.map(&:to_s) }
end
