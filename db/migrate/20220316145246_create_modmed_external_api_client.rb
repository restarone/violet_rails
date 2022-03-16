class CreateModmedExternalApiClient < ActiveRecord::Migration[6.1]
  def up
    # Subdomain.all.pluck(name).each do |name|

    # end
    api_namespace = ApiNamespace.find_by(slug: ExternalApiClient::CLIENTS[:modmed][:api_namespace_prefix])
    # check if modmed is not registered already
    modmed = ExternalApiClient.find_by(slug: ExternalApiClient::CLIENTS[:modmed][:name])
    if !modmed && !api_namespace
      # create apinamespace to support data
      api_namespace = ApiNamespace.create!(
        name: ExternalApiClient::CLIENTS[:modmed][:api_namespace_prefix],
        slug: ExternalApiClient::CLIENTS[:modmed][:api_namespace_prefix],
        version: 1,
        properties: {}.to_json
      )
      # create modmed with dummy values
      ExternalApiClient.create!(
        api_namespace_id: api_namespace.id,
        slug: ExternalApiClient::CLIENTS[:modmed][:name],
        label: ExternalApiClient::CLIENTS[:modmed][:name],
        status: ExternalApiClient::STATUSES[:stopped],
        enabled: false,
        drive_strategy: ExternalApiClient::DRIVE_STRATEGIES[:cron],
        max_requests_per_minute: 1000,
        max_retries: 3,
        metadata: {
          api_key: 'foo',
          host: 'foo',
          clinic_id: 'dermpmsandbox277',
          grant_type: 'password',
          username: 'fhir_iRHGY',
          password: 'icbBS6ecIk',
          auth_base_url: 'https://stage.ema-api.com',
          bearer_token: 'foo'
        }.to_json
      )
    end
  end

  def down
    api_namespace = ApiNamespace.find_by(slug: ExternalApiClient::CLIENTS[:modmed][:api_namespace_prefix])
    modmed = ExternalApiClient.find_by(slug: ExternalApiClient::CLIENTS[:modmed][:name])
    if modmed && api_namespace
      modmed.destroy!
      api_namespace.destroy!
    end
  end
end
