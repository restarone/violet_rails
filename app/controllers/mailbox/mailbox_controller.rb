class Mailbox::MailboxController < Mailbox::BaseController
  def show
    params[:q] ||= {}
    @message_threads_q = if params[:categories].present?
      MessageThread.joins(:messages).includes(:categories).for_category(params[:categories]).all.includes(:messages).ransack(params[:q])
    else
      MessageThread.joins(:messages).includes(:messages).ransack(params[:q])
    end

    @message_threads_q.sorts = ['messages_created_at desc', 'unread DESC NULLS LAST', 'created_at desc'] if @message_threads_q.sorts.empty?

    @message_threads = @message_threads_q.result(distinct: true).paginate(page: params[:page], per_page: params[:per_page] || 10)
  end
end