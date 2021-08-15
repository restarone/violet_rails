namespace :maintenance do
  desc "system maintenance tasks"

  task :clear_old_ahoy_visits => [:environment] do 
    p "Clearing Ahoy::Visit @ #{Time.now}"
  end
end