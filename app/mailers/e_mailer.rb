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
    
    # if additional attachment params are passed, they are included in the email
    unless params[:attachments].nil?
      Array.wrap(params[:attachments]).each do |attachment|
        attachments[attachment[:filename]] = {
          mime_type: attachment[:mime_type],
          content: attachment[:content]
        }
      end
    end
      
    mail_settings = {
      # This will make the mail addresses visible to all (no Blank Carbon Copy)
      to: @message_thread.recipients, 
      subject: @message_thread.subject,
      from: @from,
      message_id: email_message_id(@message)
    }.merge(email_headers)

    mail(mail_settings)
  end

  private
  def email_message_id(message)
    return '' if message.blank?

    "<#{message.email_message_id}>"
  end

  def in_reply_to_message_id
    last_message = messages_in_thread.last

    email_message_id(last_message)
  end

  def thread_references
    messages_in_thread.map { |message| email_message_id(message) }.join(" ")
  end

  def messages_in_thread
    @message_thread.messages.where.not(id: @message.id).reorder(created_at: :asc)
  end

  def email_headers
    {
      in_reply_to: in_reply_to_message_id,
      references: thread_references
    }.reject { |_, v| v.blank? }
  end
end
