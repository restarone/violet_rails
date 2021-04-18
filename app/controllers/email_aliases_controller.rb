class EmailAliasesController < Comfy::Admin::Cms::BaseController
  layout "comfy/admin/cms"
  before_action :ensure_authority_to_manage_email

  def new
    @email_alias = EmailAlias.new
  end


  def index
  end

  def show

  end

  def create
    email_alias = EmailAlias.new(email_alias_params)
    if email_alias.save
      flash.notice = "Email Alias created and assigned to #{email_alias.user.email}"
    else
      flash.alert = email_alias.errors.full_messages.to_sentence
    end
    redirect_to email_aliases_path
  end

  def edit

  end

  def update

  end

  def destroy

  end

  private 

  def email_alias_params
    params.require(:email_alias).permit(:name, :user_id)
  end

  def ensure_authority_to_manage_email
    unless current_user.can_manage_email
      flash.alert = "You do not have the permission to do that. Only users who can-mnage-email are allowed to perform that action."
      redirect_to admin_users_path
    end
  end
end
