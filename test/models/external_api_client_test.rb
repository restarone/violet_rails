require "test_helper"

class ExternalApiClientTest < ActiveSupport::TestCase
  setup do
    @external_api_client = external_api_clients(:modmed)
  end

  test "returns false if not enabled" do
    @external_api_client.update(enabled: false)
    refute @external_api_client.run
  end

  test "returns true if enabled & started" do
    assert @external_api_client.run
  end

  test "sets status to error if error is caught and retries are exhausted" do
    error_message = "Gateway unavailable"
    External::ApiClients::Modmed.stubs(:start).raises(StandardError, error_message)
    @external_api_client.run
    @external_api_client.reload
    assert @external_api_client.retries > @external_api_client.max_retries
    assert_equal @external_api_client.status, ExternalApiClient::STATUSES[:error]
    assert_equal @external_api_client.error_message, error_message
    assert @external_api_client.retry_in_seconds > 0
  end

  test "sets custom error_metadata if error is caught" do
    skip
  end

  test "sets current_requests_per_minute when requests are successful" do
    skip
  end

  test "sets current_workers when jobs are spawned" do
    skip
  end

  test "sets retry_in_seconds if error is caught" do
    skip
  end

  test 'sets state_metadata for tracking data ingestion state' do
    skip
  end
end
