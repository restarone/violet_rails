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



# external API client cron jobs
# ideally we can do something like this in the future
# ExternalApiClient::DRIVE_INTERVALS.keys.each do |key|
#   every eval(ExternalApiClient::DRIVE_INTERVALS[key]) do
#     rake "external_api_client:drive_cron_jobs CRON_INTERVAL=#{key}"
#   end
# end
every 1.minute do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=every_minute"
end

every 5.minutes do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=five_minutes"
end

every 10.minutes do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=ten_minutes"
end

every 30.minutes do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=thirty_minutes"
end

every 1.hour do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=every_hour"
end

every 3.hours do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=three_hours"
end

every 6.hours do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=six_hours"
end

every 12.hours do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=twelve_hours"
end

every 1.day do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=one_day"
end

every 1.week do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=one_week"
end

every 2.weeks do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=two_weeks"
end

every 1.month do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=one_month"
end

every 3.months do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=three_months"
end

every 6.months do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=six_months"
end

every 1.year do
  rake "external_api_client:drive_cron_jobs CRON_INTERVAL=one_year"
end


#  end





every 1.day do
  rake "report:send_analytics_report"
end

every 5.minutes do
  rake "api_action:rerun_failed_actions"
end

every 1.day do
  rake "maintenance:clear_discarded_api_actions"
end
