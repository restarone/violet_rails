require "test_helper"

class ExternalApiClientTest < ActiveSupport::TestCase
  setup do
    @external_api_client = external_api_clients(:test)
    Sidekiq::Testing.fake!
    @external_api_client.update!(status: ExternalApiClient::STATUSES[:sleeping])
  end

  test "returns false if not enabled" do
    @external_api_client.update(enabled: false)
    refute @external_api_client.run
  end

  test "returns true if enabled & started" do
    assert @external_api_client.run
  end

  test "sets status to error if error is caught and retries are exhausted" do
    assert @external_api_client.retries < @external_api_client.max_retries
    assert @external_api_client.retry_in_seconds == 0
    error_message = "Gateway unavailable"
    @external_api_client.evaluated_model_definition.any_instance.stubs(:start).raises(StandardError, error_message)
    
    assert_changes "@external_api_client.reload.status" do
      @external_api_client.run
      Sidekiq::Worker.drain_all
    end
    @external_api_client.reload
    assert @external_api_client.retries > @external_api_client.max_retries
    assert_equal @external_api_client.status, ExternalApiClient::STATUSES[:error]
    assert_equal @external_api_client.error_message, error_message
    assert @external_api_client.retry_in_seconds > 0
  end

  test "sets custom error_metadata if error is caught" do
    error_message = "Gateway unavailable!!"
    @external_api_client.evaluated_model_definition.any_instance.stubs(:start).raises(StandardError, error_message)
    assert_changes "@external_api_client.reload.status" do
      @external_api_client.run
      Sidekiq::Worker.drain_all
    end
    error_data = @external_api_client.error_metadata
    assert error_data["backtrace"]
    assert @external_api_client.error_message
  end

  test "sets retry_in_seconds if error is caught" do
    @external_api_client.evaluated_model_definition.any_instance.stubs(:start).raises(StandardError, 'error!')
    assert_changes "@external_api_client.reload.retry_in_seconds" do
      @external_api_client.run
      Sidekiq::Worker.drain_all
    end
  end

  test 'cron jobs are discoverable' do
    @external_api_client.update!(drive_strategy: ExternalApiClient::DRIVE_STRATEGIES[:cron], drive_every: 'every_minute')
    assert ExternalApiClient.cron_jobs[0]
  end

  test 'discover cron job that needs to be run every minute' do
    @external_api_client.update!(drive_strategy: ExternalApiClient::DRIVE_STRATEGIES[:cron], drive_every: 'every_minute')
    @external_api_client.update(last_run_at: Time.now - 2.minutes)
    discovered_jobs = ExternalApiClient.cron_jobs
    assert discovered_jobs.size > 0
    assert_equal discovered_jobs[0].id, @external_api_client.id
  end

  test 'discover cron job that needs to be run every hour' do
    @external_api_client.update!(drive_strategy: ExternalApiClient::DRIVE_STRATEGIES[:cron], drive_every: 'every_hour')
    @external_api_client.update(last_run_at: Time.now - 2.hours)
    discovered_jobs = ExternalApiClient.cron_jobs
    assert discovered_jobs.size > 0
    assert_equal discovered_jobs[0].id, @external_api_client.id
  end

  test 'does not discover cron job that ran less than a minute ago' do
    @external_api_client.update!(drive_strategy: ExternalApiClient::DRIVE_STRATEGIES[:cron], drive_every: 'every_minute')
    @external_api_client.update(last_run_at: Time.now - 2.seconds)
    discovered_jobs = ExternalApiClient.cron_jobs
    assert discovered_jobs.size == 0
  end

  test 'does not discover cron job that ran less than an hour ago' do
    @external_api_client.update!(drive_strategy: ExternalApiClient::DRIVE_STRATEGIES[:cron], drive_every: 'every_hour')
    @external_api_client.update(last_run_at: Time.now - 30.minutes)
    discovered_jobs = ExternalApiClient.cron_jobs
    assert discovered_jobs.size == 0
  end
end
