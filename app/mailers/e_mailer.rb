class EMailer < ApplicationMailer
  def ship
    @message = params[:message]
    @message_thread = params[:message_thread]
    @subdomain = Subdomain.current
    @from = if @subdomain.email_name.present?
              "#{@subdomain.email_name} <#{@subdomain.name}@#{ENV["APP_HOST"]}>"
            else
              "#{@subdomain.name}@#{ENV["APP_HOST"]}"
            end
    message_id = "#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@#{Apartment::Tenant.current}@#{ENV['APP_HOST']}"
    @message_thread.update(current_email_message_id: message_id)
    
    # if additional attachment params are passed, they are included in the email
    unless params[:attachments].nil?
      Array.wrap(params[:attachments]).each do |attachment|
        attachments[attachment[:filename]] = {
          mime_type: attachment[:mime_type],
          content: attachment[:content]
        }
      end
    end

    mail(
      # This will make the mail addresses visible to all (no Blank Carbon Copy)
      to: @message_thread.recipients, 
      subject: @message_thread.subject,
      from: @from,
      message_id: message_id
    )
  end
end
