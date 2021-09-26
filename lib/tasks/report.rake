namespace :report do
  desc "subdomain analytics and report tasks"
  
  task :send_analytics_report => [:environment] do 
    Subdomain.where.not(analytics_report_frequency: Subdomain::REPORT_FREQUENCY_MAPPING[:never]).each do |subdomain|
      if (subdomain.analytics_report_last_sent.nil? || subdomain.analytics_report_last_sent <= eval(subdomain.analytics_report_frequency).ago)  
        UserMailer.analytics_report(subdomain).deliver_now
      end
    end
  end
end