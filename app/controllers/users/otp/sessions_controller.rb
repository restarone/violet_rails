class Users::Otp::SessionsController < DeviseController
  prepend_before_action :require_no_authentication, only: [:new, :create]

  def new
    unless User.exists?(session[:otp_user_id])
      session[:otp_user_id] = nil
      redirect_to new_user_session_path 
    else
      render 'users/otp/sessions/new'
    end
  end

  def create
    resource = warden.authenticate(:otp_attempt_authenticatable, scope: resource_name)

    if resource
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      flash[:danger]= t("devise.otp.invalid")
      redirect_to users_sign_in_otp_path
    end
  end
end