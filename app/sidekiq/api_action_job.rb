class ApiActionJob
  include Sidekiq::Job

  def perform(api_action_id)
    # turning off to debug server issue related to job processing
    api_action = ApiAction.find(api_action_id)
    api_action.execute_action
  end
end
