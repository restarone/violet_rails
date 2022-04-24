class ApiActionJob
  include Sidekiq::Job

  def perform(api_action_id)
    api_action = ApiAction.find(api_action_id)
    api_action.execute_action
  end
end
