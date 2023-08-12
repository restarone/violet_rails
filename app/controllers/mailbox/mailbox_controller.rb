class Mailbox::MailboxController < Mailbox::BaseController
  def show
    params[:q] ||= {}
    @message_threads_q = if params[:categories].present?
      MessageThread.includes(:categories).for_category(params[:categories]).all.includes(:messages).ransack(params[:q])
    else
      MessageThread.all.includes(:messages).ransack(params[:q])
    end

    @message_threads = @message_threads_q.result

    @message_threads = @message_threads.sort_by_unread_messages if @message_threads_q.sorts.empty?

    @message_threads = @message_threads.paginate(page: params[:page], per_page: params[:per_page] || 10)
  end
end