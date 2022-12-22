class FireApiActionsJob
  include Sidekiq::Job

  # run error actions only after final retries
  sidekiq_retries_exhausted do |msg, exception|
    set_current_visit(msg['args'][1], msg['args'][2], msg['args'][3]) do
      ApiAction.find(msg['args'][0]).execute_error_actions(exception.message)
    end
  end

  def perform(action_id, current_user_id, current_visit_id, is_api_html_renderer_request)
    FireApiActionsJob.set_current_visit(current_user_id, current_visit_id, is_api_html_renderer_request) do
      api_action = ApiAction.find(action_id)
      api_action.execute_action(false) if api_action.present?
    end
  end

  def self.set_current_visit(current_user_id, current_visit_id, is_api_html_renderer_request)
    current_user = User.find_by(id: current_user_id)
    current_visit = Ahoy::Visit.find_by(id: current_visit_id)

    Current.set(user: current_user, visit: current_visit, is_api_html_renderer_request: is_api_html_renderer_request) do
      yield
    end
  end
end
  