require "test_helper"
require "rake"

class ReportTest < ActiveSupport::TestCase
  setup do
    @user = users(:public)
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'sends report to users who are permissioned to see' do
    @user.update(deliver_analytics_report: true)
    recipients = User.where(deliver_analytics_report: true)
    assert_difference "UserMailer.deliveries.size", +recipients.size do
      perform_enqueued_jobs do
        Rake::Task["report:send_analytics_report"].invoke
      end
    end
  end
end