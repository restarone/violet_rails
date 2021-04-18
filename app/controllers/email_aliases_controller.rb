class EmailAliasesController < Comfy::Admin::Cms::BaseController
  layout "comfy/admin/cms"
  before_action :ensure_authority_to_manage_email


  def index
  end

  def show

  end

  def create

  end

  def edit

  end

  def update

  end

  def destroy

  end

  private 

  def ensure_authority_to_manage_email
    unless current_user.can_manage_email
      flash.alert = "You do not have the permission to do that. Only users who can-mnage-email are allowed to perform that action."
      redirect_to admin_users_path
    end
  end
end
