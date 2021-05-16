class Mailbox::BaseController < Comfy::Admin::Cms::BaseController
  before_action :check_email_authorization

  def check_email_authorization
    unless current_user.can_manage_email
      flash.alert = 'You do not have permission to manage email'
      redirect_back(fallback_location: root_path)
    end
  end
end