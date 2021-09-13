class UserMailer < ApplicationMailer
  def subdomain_registration
    @subdomain_request = params[:subdomain_request]
    mail(
      to: User.where(global_admin: true).pluck(:email), 
      subject: "New Subdomain Registration",
    )
  end

  def analytics_report
    mail(
      to: User.where(deliver_analytics_report: true).pluck(:email), 
      subject: "Periodic reports for visitor analytics",
    )
  end
end
