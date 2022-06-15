class EMailer < ApplicationMailer
  def ship
    @message = params[:message]
    @message_thread = params[:message_thread]
    @from = "#{Subdomain.current.name}@#{ENV["APP_HOST"]}"
    message_id = "#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@#{Apartment::Tenant.current}@#{ENV['APP_HOST']}"
    @message_thread.update(current_email_message_id: message_id)

    # This will make the mail addresses visible to all
    mail(
      to: @message_thread.recipients, 
      subject: @message_thread.subject,
      from: @from,
      message_id: message_id
    )
  end
end
