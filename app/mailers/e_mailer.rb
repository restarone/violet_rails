class EMailer < ApplicationMailer
  include Rails.application.routes.url_helpers
  def ship
    @message = params[:message]
    @message_thread = params[:message_thread]
    @message_thread.recipients.each do |recipient|
      mail(to: recipient, subject: @message_thread.subject)
    end
  end
end
