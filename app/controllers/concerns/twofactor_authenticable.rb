module TwofactorAuthenticable
  extend ActiveSupport::Concern

 def valid_otp_attempt?(user)
    user.validate_and_consume_otp!(params[:user][:otp_attempt]) 
 end

 def prompt_for_otp_two_factor(user)
    @user = user
    UserMailer.send_otp(@user).deliver_later
    session[:otp_user_id] = user.id
 end

 def enable_2fa?
    Subdomain.current.enable_2fa
 end

 def redirect_with_js(url)
    @redirect_url = url
    render 'shared/redirect.js.erb'
 end

 def resend_otp
  user = find_user
  prompt_for_otp_two_factor(user)
  render 'users/sessions/two_factor'
 end 

 include ApplicationHelper
  def authenticate_with_otp_two_factor
    user = self.resource = find_user
    if session[:otp_user_id]
      authenticate_user_with_otp_two_factor(user)
    elsif user&.valid_password?(user_params[:password])
     if user&.current_sign_in_ip != request&.remote_ip 
      prompt_for_otp_two_factor(user)
      render 'users/sessions/two_factor'
     else
        sign_in(user)
        session.delete(:otp_user_id)
     end
    end
  end
  
  def authenticate_user_with_otp_two_factor(user)
    if valid_otp_attempt?(user)
      session.delete(:otp_user_id)
      remember_me(user) if user_params[:remember_me] == '1'
      user.save!
      sign_in(user, event: :authentication)
    else
      if params[:user][:otp_attempt].present?
        flash.now[:alert] = 'Invalid two-factor code.'
      else
        flash.now[:alert] = 'OTP Required.'
      end
      render 'users/sessions/two_factor'
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :remember_me, :otp_attempt)
  end

  def find_user
    if session[:otp_user_id]
      User.find(session[:otp_user_id])
    elsif user_params[:email]
      User.find_by(email: user_params[:email])
    end
  end

  def otp_two_factor_enabled?
    find_user&.otp_required_for_login && enable_2fa? 
  end

  def generate_and_prompt_for_otp_two_factor(user)
    @user = user
    @user.generate_two_factor_secret_if_missing!
    @user.enable_two_factor!
    UserMailer.send_otp(@user).deliver_later
    session[:otp_user_id] = user.id
    render 'users/shared/otp_visible.js.erb'
  end
end
