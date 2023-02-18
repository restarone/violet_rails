# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, 'log/whenever.log'
env :PATH, ENV['PATH']
job_type :rake, 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; cd :path && :environment_variable=:environment bundle exec rake :task --silent :output'

every 12.hours do
  rake "maintenance:clear_old_ahoy_visits"
end

every 1.minute do
  rake "external_api_client:drive_cron_jobs"
end

every 1.day do
  rake "report:send_analytics_report"
end

every 5.minutes do
  rake "api_action:rerun_failed_actions"
end

every 1.day do
  rake "maintenance:clear_discarded_api_actions"
  rake "active_storage:purge_unattached"
end
