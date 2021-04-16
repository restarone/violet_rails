class Comfy::Admin::UsersController < Comfy::Admin::Cms::BaseController
  layout "comfy/admin/cms"
  
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

  end


  def destroy
  
  end

  private 

  def invite_params
    params.require(:user).permit(:email)
  end
end