class Comfy::Admin::UsersController < Comfy::Admin::Cms::BaseController
  layout "comfy/admin/cms"
  before_action :load_user, only: [:edit, :update, :destroy]
  before_action :ensure_authority_to_manage_users, only: [:new, :invite, :edit, :update, :destroy]
  
  def index
    @users = User.all
  end

  def new
  end

  def invite
    user = User.invite!(invite_params)
    if user.persisted?
      flash.notice = "#{user.email} was invited"
      redirect_to admin_users_path
    else
      flash.alert = "User could not be invited"
    end
  end

  def edit
  end

  def update
    if @user.update(update_params)
      flash.notice = "#{@user.email} was successfully updated!"
      redirect_to admin_users_path
    else
      flash.alert = "User could not be updated"
    end
  end


  def destroy
    if @user.destroy
      flash.notice = "#{@user.email} was removed!"
      redirect_to admin_users_path
    else
      flash.alert = "User could not be destroyed"
    end
  end

  private 

  def ensure_authority_to_manage_users
    unless current_user.can_manage_users
      flash.alert = "You do not have the permission to do that. Only users who can-manage-users  are allowed to perform that action."
      redirect_to admin_users_path
    end
  end

  def load_user
    @user = User.find_by(id: params[:id])
    unless @user
      flash.alert = 'User could not be found'
      redirect_to admin_users_path
    end
  end

  def update_params
    params.require(:user).permit(:can_manage_web, :can_manage_email, :can_manage_users)
  end

  def invite_params
    params.require(:user).permit(:email)
  end
end