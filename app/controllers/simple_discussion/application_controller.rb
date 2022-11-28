class SimpleDiscussion::ApplicationController < ::ApplicationController
  layout "simple_discussion"

  before_action :redirect_if_forum_disabled

  before_action :redirect_if_not_logged_in, if: -> { Subdomain.current.forum_is_private }

  def page_number
    page = params.fetch(:page, "").gsub(/[^0-9]/, "").to_i
    page = "1" if page.zero?
    page
  end

  def is_moderator_or_owner?(object)
    is_moderator? || object.user == current_user
  end
  helper_method :is_moderator_or_owner?

  def is_moderator?
    current_user.respond_to?(:moderator) && current_user.moderator?
  end
  helper_method :is_moderator?

  def require_mod!
    unless current_user.moderator
      redirect_to_root
    end
  end

  def require_mod_or_author_for_post!
    unless is_moderator_or_owner?(@forum_post)
      redirect_to_root
    end
  end

  def require_mod_or_author_for_thread!
    unless is_moderator_or_owner?(@forum_thread)
      redirect_to_root
    end
  end

  private

  def redirect_if_not_logged_in
    unless current_user
      flash.alert = 'please sign in to view this'
      redirect_to new_user_session_path
    end
  end

  def redirect_if_forum_disabled
    unless Subdomain.current.forum_enabled
      flash.alert = 'Forum is disabled'
      redirect_to root_path
    end
  end

  def redirect_to_root
    redirect_to simple_discussion.root_path, alert: "You aren't allowed to do that."
  end

  def set_users_for_mention
    @users = User.all.as_json(only: [:id, :name, :email])
  end
end
