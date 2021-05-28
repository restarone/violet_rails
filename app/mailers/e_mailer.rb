class EMailer < ApplicationMailer
  def ship
    @message = params[:message]
    @message_thread = params[:message_thread]
    @from = "#{Subdomain.current.name}@#{ENV["APP_HOST"]}"
    message_id = "#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@#{Apartment::Tenant.current}@#{ENV['APP_HOST']}"
    @message_thread.update(current_email_message_id: message_id)
    @message_thread.recipients.each do |recipient|
      mail(
        to: recipient, 
        subject: @message_thread.subject,
        from: @from,
        message_id: message_id
      )
    end
  end
end
