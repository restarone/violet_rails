class Admin::BaseController < ApplicationController
  before_action :ensure_user_logged_in, :ensure_superuser
  layout 'admin'
  
  private

  def ensure_user_logged_in
    unless current_user
      flash.alert = 'you need to sign in'
      redirect_to new_global_admin_session_path
    end
  end

  def ensure_superuser
    unless current_user.global_admin
      flash.alert = 'you do not have permissions to access this'
      redirect_to root_path
    end
  end
end
