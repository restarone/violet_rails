namespace :api_action do
  desc "subdomain analytics and report tasks"
  
  task :rerun_failed_actions => [:environment] do 
    p "starting rerun_failed_actions task  @ #{Time.now}"
      ApiAction.where(lifecycle_stage: 'failed', action_type: [' send_email', 'send_web_request']).each do |action|
        action.execute_action
      end
    p "ending rerun_failed_actions task  @ #{Time.now}"
  end
end