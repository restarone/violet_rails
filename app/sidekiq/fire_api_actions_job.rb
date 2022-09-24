class FireApiActionsJob
  include Sidekiq::Job

  def perform(action_id, current_user_id, current_visit_id)
    current_user = User.find_by(id: current_user_id)
    current_visit = Ahoy::Visit.find_by(id: current_visit_id)

    Current.set(user: current_user, visit: current_visit) do
      api_action = ApiAction.find(action_id)

      api_action.execute_action if api_action.present?
    end
  end
end
  