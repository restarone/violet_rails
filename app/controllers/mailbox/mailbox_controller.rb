class Mailbox::MailboxController < Mailbox::BaseController
  def show
    params[:q] ||= {}
    @message_threads_q = MessageThread.all.includes(:messages).ransack(params[:q])
    @message_threads_q.sorts = ['created_at desc'] if @message_threads_q.sorts.empty?
    @message_threads = @message_threads_q.result(distinct: true).paginate(page: params[:page], per_page: params[:per_page] || 10)
  end
end