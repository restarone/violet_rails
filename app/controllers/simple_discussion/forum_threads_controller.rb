class SimpleDiscussion::ForumThreadsController < SimpleDiscussion::ApplicationController
  before_action :authenticate_user!, only: [:mine, :participating, :new, :create]
  before_action :set_forum_thread, only: [:show, :edit, :update, :destroy]
  before_action :require_mod_or_author_for_thread!, only: [:edit, :update, :destroy]

  after_action :broadcast_to_mods, only: [:create]

  def index
    params[:q] ||= {}
    @forums_threads_q =  ForumThread.pinned_first.sorted.includes(:user, :forum_category).ransack(params[:q])
    @forum_threads =@forums_threads_q.result.paginate(page: page_number).distinct

  end

  def answered
    @forum_threads = ForumThread.solved.sorted.includes(:user, :forum_category).paginate(page: page_number)
    render action: :index
  end

  def unanswered
    @forum_threads = ForumThread.unsolved.sorted.includes(:user, :forum_category).paginate(page: page_number)
    render action: :index
  end

  def mine
    @forum_threads = ForumThread.where(user: current_user).sorted.includes(:user, :forum_category).paginate(page: page_number)
    render action: :index
  end

  def participating
    @forum_threads = ForumThread.includes(:user, :forum_category).joins(:forum_posts).where(forum_posts: {user_id: current_user.id}).distinct(forum_posts: :id).sorted.paginate(page: page_number)
    render action: :index
  end

  def show
    @forum_post = ForumPost.new
    @forum_post.user = current_user

    ahoy.track(
      "subdomain-forum-thread-visit",
      {visit_id: current_visit.id, forum_thread_id: @forum_thread.id, user_id: current_user&.id}
    ) if tracking_enabled? && current_visit
  end

  def new
    @forum_thread = ForumThread.new
    @forum_thread.forum_posts.new
  end

  def create
    @forum_thread = current_user.forum_threads.new(forum_thread_params)
    @forum_thread.forum_posts.each { |post| post.user_id = current_user.id }

    if @forum_thread.save
      ForumThreadNotificationJob.perform_async(@forum_thread.id)
      ApiNamespace::Plugin::V1::SubdomainEventsService.new(@forum_thread).track_event
      redirect_to simple_discussion.forum_thread_path(@forum_thread)
    else
      render action: :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @forum_thread.update(forum_thread_params)
      redirect_to simple_discussion.forum_thread_path(@forum_thread), notice: I18n.t("your_changes_were_saved")
    else
      render action: :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @forum_thread.destroy
      flash.notice = "Thread destroyed!"
    else
      flash.notice = "Thread could not be destroyed please try again later!"
    end
    redirect_to simple_discussion.forum_threads_path
  end

  private

  def broadcast_to_mods
    if @forum_thread && @forum_thread.persisted?
      forum_mods = User.forum_mods.where.not(id: @forum_thread.user_id)
      forum_mods.each do |user|
        SimpleDiscussion::UserMailer.new_thread(@forum_thread, user).deliver_later
      end
    end
  end

  def set_forum_thread
    @forum_thread = ForumThread.friendly.find(params[:id])
  end

  def forum_thread_params
    params.require(:forum_thread).permit(:title, :forum_category_id, forum_posts_attributes: [:body])
  end
end
