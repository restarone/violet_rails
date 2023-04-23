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
  redirect_to two_factor_path
 end 

 include ApplicationHelper
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

  def generate_and_prompt_for_otp_two_factor(user)
    @user = user
    @user.generate_two_factor_secret_if_missing!
    @user.enable_two_factor!
    UserMailer.send_otp(@user).deliver_later
    session[:otp_user_id] = user.id
    render 'users/shared/otp_visible.js.erb'
  end
end
