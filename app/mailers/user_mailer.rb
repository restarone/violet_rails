class UserMailer < ApplicationMailer
  def subdomain_registration
    @subdomain_request = params[:subdomain_request]
    mail(
      to: User.where(global_admin: true).pluck(:email), 
      subject: "New Subdomain Registration",
    )
  end
end
