namespace :api_action do
  desc "subdomain analytics and report tasks"
  
  task :rerun_failed_actions => [:environment] do 
    Subdomain.all.each do |subdomain|
      Apartment::Tenant.switch subdomain.name do
        ApiAction.where(lifecycle_stage: 'failed', action_type: ['send_email', 'send_web_request']).each do |action|
          action.execute_action
        end
      end
    end
  end

  task :run_initialized_actions => [:environment] do 
    Subdomain.all.each do |subdomain|
      Apartment::Tenant.switch subdomain.name do
        ApiAction.where(lifecycle_stage: 'initialized', action_type: ['send_email', 'send_web_request']).each do |action|
          action.execute_action
        end
      end
    end
  end
end