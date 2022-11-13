# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  before_action :verify_ability_to_self_signup, only: [:new, :create]

  include TwofactorAuthenticable

  # GET /resource/sign_up
  # def new
  #   redirect_to signup_wizard_index_url(subdomain: '')
  # end

  # # POST /resource
  # def create
  #   redirect_to signup_wizard_index_url(subdomain: '')
  # end

  # GET /resource/edit
  def edit
    session.delete(:otp_user_id)
    super
  end

  # PUT /resource
  def update
    if enable_2fa? && (params[:user][:password].present? || params[:user][:password_confirmation].present?)
      if resource&.valid_password?(params[:user][:current_password]) 
        if !params[:user][:password].blank? && !params[:user][:password_confirmation].blank? && params[:user][:password] == params[:user][:password_confirmation] && !session[:otp_user_id]
          prompt_for_otp_two_factor(resource)
          render 'users/shared/otp_visible.js.erb'
        else 
          if valid_otp_attempt?(resource)
            session.delete(:otp_user_id)
            update_user
          else
            if params[:user][:otp_attempt].present?
              resource.errors.add(:otp_attempt, 'Invalid two-factor code.')
            else
              resource.errors.add(:otp_attempt, 'OTP Required')
            end
            render 'users/shared/error.js.erb'
          end
        end
      else 
        update_user
      end
    else 
      update_user
    end
  end
 
  # DELETE /resource
  def destroy
    redirect_to root_path
  end

  def update_resource(resource, params)
    resource.update_with_password(params)
  end

  def update_user 
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)
    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?
      redirect_with_js(after_update_path_for(resource))
    else
      clean_up_passwords resource
      set_minimum_password_length
      render 'users/shared/error.js.erb'
    end
    # session.delete(:otp_user_id)
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:edit, keys: [:otp_attempt])
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
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :avatar, :session_timeoutable_in,:otp_attempt])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    resolve_redirect
  end

  # The path used after sign up for inactive accounts. (when email isnt confirmed)
  def after_inactive_sign_up_path_for(resource)
    resolve_redirect
  end

  private

  def resolve_redirect
    after_sign_up_path = Subdomain.current.after_sign_up_path
    if after_sign_up_path
      return after_sign_up_path
    else
      return root_url(subdomain: Apartment::Tenant.current)
    end
  end


  def verify_ability_to_self_signup
    unless Subdomain.current.allow_user_self_signup
      flash.alert = 'User sign up is not allowed, please contact your administrator for an invitation'
      redirect_to root_path
    end
  end
end
