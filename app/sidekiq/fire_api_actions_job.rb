class FireApiActionsJob
  include Sidekiq::Job

  # run error actions only after final retries
  sidekiq_retries_exhausted do |msg, exception|
    set_current_visit(msg['args'][1], msg['args'][2]) do
      ApiAction.find(msg['args'][0]).execute_error_actions(exception.message)
    end
  end

  def perform(action_id, current_user_id, current_visit_id)
    FireApiActionsJob.set_current_visit(current_user_id, current_visit_id) do
      api_action = ApiAction.find(action_id)
      api_action.execute_action(false) if api_action.present?
    end
  end

  def self.set_current_visit(current_user_id, current_visit_id)
    current_user = User.find_by(id: current_user_id)
    current_visit = Ahoy::Visit.find_by(id: current_visit_id)

    Current.set(user: current_user, visit: current_visit) do
      yield
    end
  end
end
  