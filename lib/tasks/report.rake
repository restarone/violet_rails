namespace :report do
  desc "system maintenance tasks"
  
  task :send_analytics_report => [:environment] do 
    Subdomain.where.not(analytics_report_frequency: Subdomain::REPORT_FREQUENCY_MAPPING[:never]).each do |subdomain|
      if (subdomain.analytics_report_last_sent.nil? || subdomain.analytics_report_last_sent < eval(subdomain.analytics_report_frequency).ago)
        AnalyticsReportService.new(subdomain).call
      end
    end
  end
end