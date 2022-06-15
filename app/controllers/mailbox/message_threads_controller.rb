class Mailbox::MessageThreadsController < Mailbox::BaseController
  before_action :track_ahoy_visit, only: %i[show], raise: false
  before_action :load_thread, except: [:new, :create]

  def show
    ahoy.track(
      "subdomain-email-visit",
      {visit_id: current_visit.id, message_thread_id: @message_thread.id, user_id: current_user.id}
    ) if Subdomain.current.tracking_enabled & current_visit
  end

  def new
    @message_thread = MessageThread.new
  end

  def create
    # remove empty string (a side-effect of rails select fields)
    params[:message_thread][:recipients].delete("")
    @message_thread = MessageThread.new(message_thread_params)
    @message = Message.new(message_params[:message].merge!(message_thread: @message_thread))
    if @message_thread.save && @message.save
      flash.notice = "Sent to #{@message_thread.recipients.join(', ')}"
      redirect_to mailbox_message_thread_path(id: @message_thread.id)
    else
      flash.alert = "errors: #{@message_thread.errors.full_messages.to_sentence}  #{@message.errors.full_messages.to_sentence}"
      if @message_thread.persisted?
        redirect_to mailbox_message_thread_path(id: @message_thread.id)
      else
        redirect_back(fallback_location: root_path)
      end
    end
  end

  def send_message
    @message = Message.new(message_params[:message].merge!(message_thread: @message_thread))
    if @message.save
      flash.notice = "Sent to #{@message_thread.recipients.join(', ')}"
    else
      flash.alert = @message.errors.full_messages.to_sentence
    end
    redirect_back(fallback_location: mailbox_message_thread_path(id: @message_thread.id))
  end

  def destroy
    if @message_thread.destroy
      flash.notice = 'Email thread deleted!'
    else
      flash.alert = 'Email thread could not be deleted. Please try again later'
    end
    redirect_to mailbox_path
  end

  private
  def message_params
    params.require(:message_thread).permit(
      message: [
        :content
      ]
    )
  end

  def message_thread_params
    params.require(:message_thread).permit(
      :subject,
      recipients: []
    )
  end

  def load_thread
    @message_thread = MessageThread.find_by(id: params[:id])
    unless @message_thread
      flash.alert = 'Could not find thread'
      redirect_back(fallback_location: root_path)
    end
  end
end