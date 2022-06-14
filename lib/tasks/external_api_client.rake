namespace :external_api_client do
  desc "tasks for connecting to external systems (anything backed by ExternalApiClient"
  
  task :drive_cron_jobs => [:environment] do |t, args|
    Subdomain.add_to_subdomains('public').each do |subdomain|
      Apartment::Tenant.switch subdomain.name do
        external_api_clients = ExternalApiClient.cron_jobs
        p "**running #{external_api_clients.size} ExternalApiClient cron jobs for #{subdomain.name}** @ #{Time.now}"
        external_api_clients.each do |external_api_client|
          external_api_client.run
        end
      end
    end
  end
end