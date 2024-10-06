class Mailbox::TrackingController < ApplicationController
  def open
    emails = params[:emails]
    message_id = params[:message_id]
    email_uuid = params[:email_uuid]
    message = Message.find_by(id: message_id, email_message_id: email_uuid)
    ip = request.ip
    user_agent = request.user_agent

    if message
      message.update(opened: true)
      # mark as opened
    end

    render json: { status: 200, code: 'OK' }
  end
end