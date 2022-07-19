class ExternalApiClientJob
  include Sidekiq::Job

  def perform(id)
    external_api_client = ExternalApiClient.find_by(id: id)
    external_api_client.update(last_run_at: Time.now)
    external_api_interface = external_api_client.evaluated_model_definition
    external_api_client_runner = external_api_interface.new(external_api_client: external_api_client)
    retries = nil
    begin
      external_api_client.reload
      retries = external_api_client.retries
      external_api_client.update!(status: ExternalApiClient::STATUSES[:running])
      external_api_client_runner.start
    rescue StandardError => e
      external_api_client.reload
      external_api_client.update!(error_message: e.message) 
      if retries <= external_api_client.max_retries
        external_api_client.update!(retries: retries + 1)
        max_sleep_seconds = Float(2 ** retries)
        sleep_for_seconds = rand(0..max_sleep_seconds)
        external_api_client.update!(retry_in_seconds: max_sleep_seconds)
        external_api_client.update!(status: ExternalApiClient::STATUSES[:sleeping])
        sleep sleep_for_seconds
        retry
      else
        # client is considered dead at this point, fire off a flare
        external_api_client.update!(
          error_message: "#{e.message}",
          status: ExternalApiClient::STATUSES[:error],
          error_metadata: {
            backtrace: e.backtrace
          }
        )
      end
    else
      # if run successfully we stop the job until the next invocation
      external_api_client.stop
    end
  end
end
