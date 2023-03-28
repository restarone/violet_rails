namespace :ahoy do
  desc "Filling empty geo-location entries in ahoy_visit table"

  task fill_empty_location_entries: :environment do
    Subdomain.all_with_public_schema.each do |subdomain|
      # Gather all visits with nil longitude, this should suffice.
      visits = subdomain.ahoy_visits.where(:longitude => nil).find_each(batch_size: 1000)

      # Iterate over each visit in visits and queue the GeocodeJob to get the geodata and update the record.
      visits.each do |visit|
        # This job actually queues another job called GeocodeV2Job that does the actual lookup.
        Ahoy::GeocodeJob.perform_now(visit)
      end
    end
  end
end