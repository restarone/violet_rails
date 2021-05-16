class Mailbox::MailboxController < Mailbox::BaseController
  def show
    @message_threads = MessageThread.all.order(created_at: :desc)
  end
end