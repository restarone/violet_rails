class FireApiActionsJob
  include Sidekiq::Job

  def perform(api_resource_id, action_class, current_user_id, current_visit_id)
    current_user = User.find_by(id: current_user_id)
    current_visit = Ahoy::Visit.find_by(id: current_visit_id)

    Current.set(user: current_user, visit: current_visit) do
      api_resource = ApiResource.find(api_resource_id)
  
      api_resource.execute_model_context_api_actions(action_class)
    end
  end
end
  