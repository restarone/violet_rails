class FireApiActionsJob
  include Sidekiq::Job

  def perform(api_resource_id, action_class)
    api_resource = ApiResource.find(api_resource_id)

    api_resource.execute_model_context_api_actions(action_class)
  end
end
  