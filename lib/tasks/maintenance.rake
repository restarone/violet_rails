namespace :maintenance do
  desc "system maintenance tasks"

  task :clear_old_ahoy_visits => [:environment] do 
    p "clearing ahoy visits @ #{Time.now.utc}"
  end
end