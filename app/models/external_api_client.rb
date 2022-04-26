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

  DRIVE_INTERVALS = {
    every_minute: '1.minute',
    five_minutes: '5.minutes',
    ten_minutes: '10.minutes',
    thirty_minutes: '30.minutes',
    every_hour: '1.hour',
    three_hours: '3.hours',
    six_hours: '6.hours',
    twelve_hours: '12.hours',
    one_day: '1.day',
    one_week: '1.week',
    two_weeks: '2.weeks',
    one_month: '1.month',
    three_months: '3.months',
    six_months: '6.months',
    one_year: '1.year',
  }

  extend FriendlyId
  friendly_id :label, use: :slugged
  belongs_to :api_namespace

  validates :status, inclusion: { in: ExternalApiClient::STATUSES.keys.map(&:to_s)  }
  validates :drive_strategy, inclusion: { in: ExternalApiClient::DRIVE_STRATEGIES.keys.map(&:to_s) }

  validates :drive_every, presence: true, if: -> { drive_strategy == ExternalApiClient::DRIVE_STRATEGIES[:cron] }

  validates :drive_every, inclusion: { in: ExternalApiClient::DRIVE_INTERVALS.keys.map(&:to_s) }, allow_blank: true, allow_nil: true

  def self.cron_jobs(interval)
    ExternalApiClient.where(drive_strategy: ExternalApiClient::DRIVE_STRATEGIES[:cron], drive_every: interval)
  end

  def run
    return false if !self.enabled || self.status == ExternalApiClient::STATUSES[:error]
    ExternalApiClientJob.perform_async(self.id)
  end

  def evaluated_model_definition
    return eval(self.model_definition)
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
