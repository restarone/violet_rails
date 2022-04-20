# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  before_action :verify_ability_to_self_signup, only: [:new, :create]

  # GET /resource/sign_up
  # def new
  #   redirect_to signup_wizard_index_url(subdomain: '')
  # end

  # # POST /resource
  # def create
  #   redirect_to signup_wizard_index_url(subdomain: '')
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  def destroy
    redirect_to root_path
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:subdomain])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :avatar, :session_timeoutable_in])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    return root_url(subdomain: Apartment::Tenant.current)
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    return root_url(subdomain: Apartment::Tenant.current)
  end

  private


  def verify_ability_to_self_signup
    unless Subdomain.current.allow_user_self_signup
      flash.alert = 'User sign up is not allowed, please contact your administrator for an invitation'
      redirect_to root_path
    end
  end
end
