namespace :maintenance do
  desc "system maintenance tasks"

  task :clear_old_ahoy_visits => [:environment] do 
    p Ahoy::Visit.last.inspect
  end
end