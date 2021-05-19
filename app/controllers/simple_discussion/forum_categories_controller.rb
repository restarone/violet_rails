class SimpleDiscussion::ForumCategoriesController < SimpleDiscussion::ApplicationController
  before_action :set_category, only: [:index, :destroy, :update]
  before_action :require_mod!, only: [:new, :create, :destroy, :update]

  def index
    @forum_threads = ForumThread.where(forum_category: @category) if @category.present?
    @forum_threads = @forum_threads.pinned_first.sorted.includes(:user, :forum_category).paginate(per_page: 10, page: page_number)
    render "simple_discussion/forum_threads/index"
  end

  def new
    @category = ForumCategory.new
  end

  def create
    @category = ForumCategory.new(forum_category_params)
    if @category.save
      flash.notice = 'Created!'
      redirect_to simple_discussion.forum_threads_path
    else
      render action: :new
    end
  end

  def destroy
    if @category.destroy
      flash.notice = 'Destroyed!'  
    else
      flash.alert = "could not destroy"
    end
    redirect_to simple_discussion.forum_threads_path
  end

  def update
    if @category.update(forum_category_params)
      flash.notice = 'updated!'
      redirect_to simple_discussion.forum_category_forum_threads_path(id: @category.slug)
    else
      render action: :edit
    end
  end

  private

  def forum_category_params
    params.require(:forum_category).permit(
      :name,
      :slug,
      :color
    )
  end

  def set_category
    @category = ForumCategory.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to simple_discussion.forum_threads_path
  end
end
