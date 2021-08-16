namespace :maintenance do
  desc "system maintenance tasks"

  task :clear_old_ahoy_visits => [:environment] do 
    Subdomain.all.each do |subdomain|
      Apartment::Tenant.switch subdomain.name do
        if subdomain.purge_visits_every != Subdomain::TRACKING_PURGE_MAPPING[:never]
          p "clearing old ahoy visits for [#{subdomain.name}] @ #{Time.now}"
          visits = Ahoy::Visit.where("started_at < ?", eval("#{subdomain.purge_visits_every}.ago"))
          p "#{visits.size} visits eligible for deletion"
          visits.in_batches do |batch|
            p "cleared old ahoy visits @ #{Time.now}"
            batch.destroy_all
          end
          p "clearing old ahoy events @ #{Time.now}"
          events = Ahoy::Event.where("time < ?", eval("#{subdomain.purge_visits_every}.ago"))
          p "#{events.size} events eligible for deletion"
          events.in_batches do |batch|
            batch.destroy_all
          end
        end
      end
    end
  end
end