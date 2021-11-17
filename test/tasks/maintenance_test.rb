require "test_helper"
require "rake"

class MaintenanceTest < ActiveSupport::TestCase
  setup do
    @api_action = api_actions(:one)
    @api_action.update!(created_at: 2.years.ago, lifecycle_stage: 'discarded')
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'rerun failed api actions' do
    assert_difference "ApiAction.all.count", -1 do
      Rake::Task["maintenance:clear_discarded_api_actions"].invoke
    end
  end
end