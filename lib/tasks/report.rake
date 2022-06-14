namespace :report do
  desc "subdomain analytics and report tasks"

  task :send_analytics_report => [:environment] do 
    p "starting send_analytics_report task  @ #{Time.now}"
    subdomains = Subdomain.all_with_public_schema
    subdomains.reject {|subdomain| subdomain.analytics_report_frequency == Subdomain::REPORT_FREQUENCY_MAPPING[:never]}.each do |subdomain|
      if (subdomain.analytics_report_last_sent.nil? || subdomain.analytics_report_last_sent <= eval(subdomain.analytics_report_frequency).ago)
        Apartment::Tenant.switch subdomain.name do
          p "sending analytics report for subdomain: #{subdomain.name} @ #{Time.now}"
          UserMailer.analytics_report(subdomain).deliver_now
        end
      end
    end
    p "ending send_analytics_report task  @ #{Time.now}"
  end
end