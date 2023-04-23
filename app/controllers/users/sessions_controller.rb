# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  protect_from_forgery with: :exception, prepend: true, except: :destroy

  # GET /resource/sign_in
  # def new
  #   # session.delete(:otp_user_id)
  #   super
  # end

  def create
    self.resource = warden.authenticate!(:database_authenticatable, auth_options)
  
    if prompt_for_otp?(resource)
      sign_out(resource)
      UserMailer.send_otp(resource).deliver_later
      session[:otp_user_id] = resource.id
      redirect_to users_sign_in_otp_path
    else
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)

      redirect_to after_sign_in_path_for(resource), status: :see_other
    end
  end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  def prompt_for_otp?(resource)
    Subdomain.current.enable_2fa && resource.otp_required_for_login && resource.last_sign_in_ip != resource.current_sign_in_ip 
  end
end
