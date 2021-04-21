class Mailbox::MessageThreadsController < Mailbox::BaseController
  before_action :load_mailbox
  before_action :load_thread, except: [:new, :create]

  def show
  end

  def new
    @message_thread = MessageThread.new
  end

  def create
    @message_thread = MessageThread.new(message_thread_params)
    if @message_thread.save
      flash.notice = "Sent to #{@message_thread.messages.first.to}"
      redirect_to mailbox_message_threads_path
    else
      flash.alert = @message_thread.errors.full_messages.to_sentence
    end
  end

  private

  def message_thread_params
    params.require(:message_thread).permit(
      message: [
        :content
      ]
    )
  end

  def load_thread
    @message_thread = MessageThread.find_by(id: params[:id])
    unless @message_thread
      flash.alert = 'Could not find thread'
      redirect_back(fallback_location: root_path)
    end
  end

  def load_mailbox
    @mailbox = Mailbox.first
  end
end