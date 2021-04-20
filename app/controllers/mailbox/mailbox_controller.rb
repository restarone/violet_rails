class Mailbox::MailboxController < Mailbox::BaseController
  before_action :load_mailbox

  def show
    if @mailbox
      @message_threads = @mailbox.message_threads
    else
      flash.alert = 'You do not have access to an emailbox. Please contact your admin'
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def load_mailbox
    @mailbox = Mailbox.first
  end
end