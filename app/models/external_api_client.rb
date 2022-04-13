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

  CLIENTS = {
    modmed: {
      name: 'modmed',
      api_namespace_prefix: 'modmed'
    }
  }

  extend FriendlyId
  friendly_id :label, use: :slugged
  belongs_to :api_namespace

  validates :status, inclusion: { in: ExternalApiClient::STATUSES.keys.map(&:to_s)  }
  validates :drive_strategy, inclusion: { in: ExternalApiClient::DRIVE_STRATEGIES.keys.map(&:to_s) }

  def run
    return false if !self.enabled || self.status == ExternalApiClient::STATUSES[:error]
    external_api_interface = eval(self.model_definition)
    external_api_interface_supervisor = external_api_interface.new(external_api_client: self)
    retries = nil
    begin
      self.reload
      retries = self.retries
      self.update(status: ExternalApiClient::STATUSES[:running])
      external_api_interface_supervisor.start
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
        # client is considered dead at this point, fire off a flare
        self.update(
          error_message: "#{e.message} - #{e.backtrace}",
          status: ExternalApiClient::STATUSES[:error]
        )
        external_api_interface_supervisor.log
      end
    end
    return external_api_interface_supervisor
  end

  def stop
    self.update(status: ExternalApiClient::STATUSES[:stopped])
  end

  def clear_error_data
    self.update(
      error_message: nil,
      error_metadata: nil,
      status: ExternalApiClient::STATUSES[:stopped],
      retries: 0
    )
  end

  def clear_state_data
    self.update(
      state_metadata: nil,
    )
  end

  def get_metadata
    JSON.parse(self.reload.metadata).deep_symbolize_keys
  end

  def set_metadata(hash)
    self.update(metadata: hash.to_json)
  end
end
