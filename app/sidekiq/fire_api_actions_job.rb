class FireApiActionsJob
  include Sidekiq::Job

  def perform(api_action_ids, action_class, current_user_id, current_visit_id)
    current_user = User.find_by(id: current_user_id)
    current_visit = Ahoy::Visit.find_by(id: current_visit_id)

    Current.set(user: current_user, visit: current_visit) do
      api_actions = action_class.constantize.where(id: api_action_ids)
  
      api_actions.execute_model_context_api_actions
    end
  end
end
  