class Mailbox::MessageThreadsController < Mailbox::BaseController
  before_action :load_mailbox, :load_thread

  def show

  end

  private

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