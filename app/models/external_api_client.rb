class ExternalApiClient < ApplicationRecord
  include JsonbFieldsParsable

  attr_accessor :require_webhook_verification, :default_model_definition, :default_webhook_driven_model_definition

  STATUSES = {
    stopped: 'stopped',
    running: 'running',
    error: 'error',
    sleeping: 'sleeping'
  }

  DRIVE_STRATEGIES = {
    on_demand: 'on_demand',
    cron: 'cron',
    webhook: 'webhook'
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

  SKIPPABLE_KEYWORDS = ['render'].freeze

  DEFAULT_MODEL_DEFINITION = 
"class ExternalApiConnection
  def initialize(parameters)
    @external_api_client = parameters[:external_api_client]
  end

  def start
    @external_api_client.api_namespace.api_resources.create(
      properties: {
        request_body: {}
      }
    )
  end
end

ExternalApiConnection"

  DEFAULT_WEBHOOK_DRIVEN_MODEL_DEFINITION = 
"class WebhookDrivenConnection
  def initialize(parameters)
    @external_api_client = parameters[:external_api_client]
  
    # rails request object accessable for webhook, https://api.rubyonrails.org/classes/ActionDispatch/Request.html
    @payload = parameters[:request]&.request_parameters
  end
  
  def start
    object = @external_api_client.api_namespace.api_resources.create(
      properties: {
        request_body: @payload
      }
    )
    # render the object as the response
    render json: { result: object }
  end
end

WebhookDrivenConnection"

  extend FriendlyId

  before_save :remove_webhook_verification_method, unless: -> { (require_webhook_verification.nil? || ActiveModel::Type::Boolean.new.cast(require_webhook_verification)) }

  after_initialize do
    self.default_webhook_driven_model_definition = DEFAULT_WEBHOOK_DRIVEN_MODEL_DEFINITION
    self.default_model_definition = DEFAULT_MODEL_DEFINITION

    self.model_definition = DEFAULT_WEBHOOK_DRIVEN_MODEL_DEFINITION if drive_strategy == ExternalApiClient::DRIVE_STRATEGIES[:webhook] && self.new_record? && !self.will_save_change_to_model_definition?
  end

  friendly_id :label, use: :slugged
  belongs_to :api_namespace

  validates :status, inclusion: { in: ExternalApiClient::STATUSES.keys.map(&:to_s)  }
  validates :drive_strategy, inclusion: { in: ExternalApiClient::DRIVE_STRATEGIES.keys.map(&:to_s) }

  validates :drive_every, presence: true, if: -> { drive_strategy == ExternalApiClient::DRIVE_STRATEGIES[:cron] }

  validates :drive_every, inclusion: { in: ExternalApiClient::DRIVE_INTERVALS.keys.map(&:to_s) }, allow_blank: true, allow_nil: true
  validates :model_definition, safe_executable: { skip_keywords: SKIPPABLE_KEYWORDS }

  has_one :webhook_verification_method

  accepts_nested_attributes_for :webhook_verification_method

  def self.cron_jobs
    intervals = ExternalApiClient.pluck(:drive_every).compact
    runnable_external_api_clients = []
    ExternalApiClient.where(drive_strategy: ExternalApiClient::DRIVE_STRATEGIES[:cron]).each do |external_api_client|
      if !external_api_client.last_run_at
        runnable_external_api_clients << external_api_client
        next
      end
      last_run = ExternalApiClient::DRIVE_INTERVALS[external_api_client.drive_every.to_sym]
      if external_api_client.last_run_at < Time.at(eval("#{last_run}.ago"))
        runnable_external_api_clients << external_api_client
      end
      next
    end
    return runnable_external_api_clients
  end

  def run(args = {})
    # prevent triggering if its not enabled or the status is error (means that the custom model definition raised an error and it bubbled up)
    return false if !self.enabled || self.status == ExternalApiClient::STATUSES[:error]
    # prevent race conditions, if a client is running already-- dont run
    return false if self.status == ExternalApiClient::STATUSES[:running]
    ExternalApiClientJob.perform_async(self.id, args.deep_stringify_keys)
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
    self.reload.metadata.deep_symbolize_keys
  end

  def set_metadata(hash)
    self.update(metadata: hash)
  end

  def remove_webhook_verification_method
    self.webhook_verification_method&.destroy
  end
end
