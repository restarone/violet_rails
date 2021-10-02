class UserMailer < ApplicationMailer
  def subdomain_registration
    @subdomain_request = params[:subdomain_request]
    mail(
      to: User.where(global_admin: true).pluck(:email), 
      subject: "New Subdomain Registration",
    )
  end

  def analytics_report(subdomain)
    Apartment::Tenant.switch subdomain.name do
      mail_to = User.where(deliver_analytics_report: true).pluck(:email)
      return if mail_to.empty?

      @report = AnalyticsReportService.new(subdomain).call
      subdomain.update(analytics_report_last_sent: Time.zone.now)
      p "sending analytics report for #{mail_to.join(', ')}"
      mail(
        to: mail_to,
        subject: "Analytics report for #{@report[:start_date]} - #{@report[:end_date]}"
      )
    end
  end
end
