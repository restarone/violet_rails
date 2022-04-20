class ApiResourceSpawnJob
  include Sidekiq::Job

  def perform(api_namespace_id, json = {})
    api_namespace = ApiNamespace.find(api_namespace_id)
    api_resource = api_namespace.api_resources.create!(
      properties: json
    )
    api_namespace.create_api_actions.each{|action| action.execute_action}
  end
end
