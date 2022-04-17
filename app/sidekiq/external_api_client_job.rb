class ExternalApiClientJob
  include Sidekiq::Job

  def perform(id)
    external_api_client = ExternalApiClient.find_by(id: id)
    external_api_client.run
  end
end
