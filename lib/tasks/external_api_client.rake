namespace :external_api_client do
  desc "tasks for connecting to external systems (anything backed by ExternalApiClient"
  
  task :drive_cron_jobs => [:environment] do |t, args|
    Subdomain.all.to_a.push(Subdomain.new(name: 'public')).each do |subdomain|
      Apartment::Tenant.switch subdomain.name do
        # ENV['CRON_INTERVAL'] is passed by schedule.rb
        api_clients = ExternalApiClient.cron_jobs(ENV['CRON_INTERVAL'])
        p "**running #{api_clients.size} ExternalApiClient cron jobs for #{subdomain.name}** @ #{Time.now}"
        api_clients.each do |api_client|
          api_client.run
        end
      end
    end
  end
end