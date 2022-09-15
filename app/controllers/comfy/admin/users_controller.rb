class Comfy::Admin::UsersController < Comfy::Admin::Cms::BaseController
  layout "comfy/admin/cms"
  before_action :track_ahoy_visit,  only: %i[update], raise: false
  before_action :load_user, only: [:edit, :update, :destroy]
  before_action :ensure_authority_to_manage_users
  before_action :set_default_api_accessibility_param, only: :update

  def index
    params[:q] ||= {}
    @users_q =
      if params[:categories].present?
        User.includes(:categories).for_category(params[:categories]).ransack(params[:q])
      else
        User.ransack(params[:q])
      end
    @users = @users_q.result.paginate(page: params[:page], per_page: 10)
  end

  def new
  end

  def invite
    user = User.invite!(invite_params)
    if user.persisted?
      flash.notice = "#{user.email} was invited"
      redirect_to admin_users_path
    else
      redirect_to admin_users_path
      flash.alert = "User could not be invited"
    end
  end

  def edit
    params[:q] ||= {}
    @visits_q = @user.previous_ahoy_visits.ransack(params[:q])
    @visits = @visits_q.result.paginate(page: params[:page], per_page: 10)
  end

  def update
    if @user.update(update_params)
      ahoy.track(
        "subdomain-user-update",
        {visit_id: current_visit.id, edited_user_id: @user.id, user_id: current_user.id}
      ) if tracking_enabled? && current_visit

      flash.notice = "#{@user.email} was successfully updated!"
      redirect_to admin_users_path
    else
      redirect_to admin_users_path
      flash.alert = "User could not be updated"
    end
  end


  def destroy
    if @user.destroy
      flash.notice = "#{@user.email} was removed!"
      redirect_to admin_users_path
    else
      redirect_to admin_users_path
      flash.alert = "User could not be destroyed"
    end
  end

  private

  def load_user
    @user = User.find_by(id: params[:id])
    unless @user
      flash.alert = 'User could not be found'
      redirect_to admin_users_path
    end
  end

  def update_params
    params.require(:user).permit(
      :can_manage_web,
      :can_manage_blog,
      :can_manage_email,
      :can_manage_users,
      :can_manage_api,
      :can_manage_analytics,
      :can_manage_files,
      :moderator,
      :name,
      :can_view_restricted_pages,
      :deliver_analytics_report,
      :can_manage_subdomain_settings,
      :can_access_admin,
      :deliver_error_notifications,
      category_ids: [],
      api_accessibility: {}
    )
  end

  def invite_params
    params.require(:user).permit(:email)
  end

  def set_default_api_accessibility_param
    params[:user].merge!(api_accessibility: {}) if params[:user].present? && params.dig(:user, :api_accessibility).blank?
  end
end