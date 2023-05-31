require "test_helper"
require "rake"

class ExternalApiClientCronJobTest < ActiveSupport::TestCase
  setup do
    @external_api_client = external_api_clients(:test)
    @external_api_client.update!(

      drive_strategy: ExternalApiClient::DRIVE_STRATEGIES[:cron],
      drive_every: ExternalApiClient::DRIVE_INTERVALS.keys[0].to_s
    )
    Sidekiq::Testing.fake!
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  teardown do
    Rake::Task.clear
  end

  test 'invoke task for running external api client tasks' do
    error_msg = 'error!'
    @external_api_client.evaluated_model_definition.any_instance.stubs(:start).raises(StandardError, error_msg)
    refute @external_api_client.reload.error_message

    perform_enqueued_jobs do
      Rake::Task["external_api_client:drive_cron_jobs"].invoke
      Sidekiq::Worker.drain_all
    end

    assert_equal @external_api_client.reload.error_message, error_msg
    assert @external_api_client.last_run_at
  end
end