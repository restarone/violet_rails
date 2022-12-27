class ApiResourceSpawnJob
  include Sidekiq::Job

  def perform(api_namespace_id, json_string = "")
    api_namespace = ApiNamespace.find(api_namespace_id)
    api_resource = api_namespace.api_resources.create!(
      # convert back to hash because sidekiq doesnt like taking a hash as an argument-- it prefers json instead
      properties: JSON.parse(json_string).to_h
    )
  end
end
