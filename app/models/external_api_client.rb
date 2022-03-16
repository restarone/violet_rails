class ExternalApiClient < ApplicationRecord
  STATUSES = {
    stopped: 'stopped',
    running: 'running',
    error: 'error',
    sleeping: 'sleeping'
  }

  DRIVE_STRATEGIES = {
    on_demand: 'on_demand',
    cron: 'cron'
  }

  CLIENT_INTERFACE_MAPPING = {
    modmed: 'External::ApiClients::Modmed'
  }

  extend FriendlyId
  friendly_id :label, use: :slugged
  belongs_to :api_namespace

  validates :status, inclusion: { in: ExternalApiClient::STATUSES.keys.map(&:to_s)  }
  validates :drive_strategy, inclusion: { in: ExternalApiClient::DRIVE_STRATEGIES.keys.map(&:to_s) }

  def run
    return false if !self.enabled || self.status == ExternalApiClient::STATUSES[:error]
    retries = nil
    begin
      self.reload
      retries = self.retries
      self.update(status: ExternalApiClient::STATUSES[:running])
      ExternalApiClient::CLIENT_INTERFACE_MAPPING[self.slug.to_sym].constantize.start(self)
    rescue StandardError => e
      self.update(error_message: e.message) 
      if retries <= self.max_retries
        self.update(retries: retries + 1)
        max_sleep_seconds = Float(2 ** retries)
        sleep_for_seconds = rand(0..max_sleep_seconds)
        self.update(retry_in_seconds: max_sleep_seconds)
        self.update(status: ExternalApiClient::STATUSES[:sleeping])
        sleep sleep_for_seconds
        retry
      else
        self.update(
          error_message: e.message,
          status: ExternalApiClient::STATUSES[:error]
        )
        ExternalApiClient::CLIENT_INTERFACE_MAPPING[self.slug.to_sym].constantize.log(self)
      end
    end
    
  end
end
