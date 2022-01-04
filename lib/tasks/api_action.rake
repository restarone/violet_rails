namespace :api_action do
  desc "subdomain analytics and report tasks"
  
  task :rerun_failed_actions => [:environment] do 
    p "starting rerun_failed_actions task  @ #{Time.now}"
    Subdomain.all.each do |subdomain|
      Apartment::Tenant.switch subdomain.name do
        p "executing failed action for [#{subdomain.name}] @ #{Time.now}"
        ApiAction.where(lifecycle_stage: 'failed', action_type: ['send_email', 'send_web_request']).each do |action|
          action.execute_action
        end
        p "executing failed action  for [#{subdomain.name}] @ #{Time.now}"
      end
    end
    p "ending rerun_failed_actions task  @ #{Time.now}"
  end
end