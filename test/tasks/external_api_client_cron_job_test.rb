require "test_helper"
require "rake"

class ExternalApiClientCronJobTest < ActiveSupport::TestCase
  setup do
    @external_api_client = external_api_clients(:test)
    @external_api_client.update!(

      drive_strategy: ExternalApiClient::DRIVE_STRATEGIES[:cron],
      drive_every: ExternalApiClient::DRIVE_INTERVALS.keys[0].to_s
    )
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'invoke task for running external api client tasks' do
    error_msg = 'error!'
    @external_api_client.evaluated_model_definition.any_instance.stubs(:start).raises(StandardError, error_msg)
    # passed by schedule.rb
    ENV['CRON_INTERVAL'] = @external_api_client.drive_every
    refute @external_api_client.reload.error_message
    Rake::Task["external_api_client:drive_cron_jobs"].invoke
    assert_equal @external_api_client.reload.error_message, error_msg
  end
end