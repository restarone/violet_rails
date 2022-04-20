class ApiResourceSpawnJob
  include Sidekiq::Job

  def perform(api_namespace_id, json = {})
    api_namespace = ApiNamespace.find(api_namespace_id)
    api_resource = api_namespace.api_resources.create!(
      properties: json
    )
  end
end
