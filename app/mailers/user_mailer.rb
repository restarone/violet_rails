class UserMailer < ApplicationMailer
  def subdomain_registration
    @subdomain_request = params[:subdomain_request]
    mail(
      to: User.where(global_admin: true).pluck(:email), 
      subject: "New Subdomain Registration",
    )
  end

  def analytics_report(subdomain)
    mail_to = User.where(deliver_analytics_report: true).pluck(:email)
    p "sending analytics report for #{mail_to.size} users in subdomain: #{subdomain.name}"
    return if mail_to.empty?

    @report = AnalyticsReportService.new(subdomain).call
    subdomain.update(analytics_report_last_sent: Time.zone.now.at_beginning_of_day)
    p "sending analytics report for #{mail_to.join(', ')}"
    mail(
      to: mail_to,
      subject: "Analytics report for #{@report[:start_date]} - #{@report[:end_date]}"
    )
  end

  def send_otp(user)
    @user = user
  
    mail(
      to: [user.email],
      subject: "OTP"
    )
  end
end
