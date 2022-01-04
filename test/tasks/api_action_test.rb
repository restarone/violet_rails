require "test_helper"
require "rake"

class ApiActionTest < ActiveSupport::TestCase
  setup do
    @api_namespace = api_namespaces(:one)
    @failed_action = api_actions(:three)
    @failed_action.update(lifecycle_stage: 'failed')
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'rerun failed api actions' do
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size
    assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size", -(failed_action_counts) do
      Rake::Task["api_action:rerun_failed_actions"].invoke
    end
  end
end