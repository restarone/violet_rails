class Users::InvitationsController < Devise::InvitationsController
 
def update 
  self.resource = User.find_by_invitation_token( params[:user][:invitation_token], false)

  if params[:user][:password] == params[:user][:password_confirmation] && enable_2fa?
    unless params[:user][:otp_attempt].present?
    prompt_for_otp_two_factor(resource)
  else
    if  valid_otp_attempt?(resource)
      new_user
    else 
      resource.errors.add(:otp_attempt, 'Invalid two-factor code.')
      render 'users/invitations/error.js.erb'
    end
  end
  else
   new_user
  end
end

def new_user
  raw_invitation_token = update_resource_params[:invitation_token]
    self.resource = accept_resource
    invitation_accepted = resource.errors.empty?

    yield resource if block_given?

    if invitation_accepted
      if resource.class.allow_insecure_sign_in_after_accept
        resource.after_database_authentication
        sign_in(resource_name, resource)
        redirect_with_js(after_accept_path_for(resource))
      else
        redirect_with_js(new_session_path(resource_name))
      end
    else
      resource.invitation_token = raw_invitation_token
    end
end

def update_resource_params
  devise_parameter_sanitizer.sanitize(:accept_invitation)
end

def resource_from_invitation_token
  unless params[:invitation_token] && self.resource = resource_class.find_by_invitation_token(params[:invitation_token], true)
    redirect_to after_sign_out_path_for(resource_name)
  end
end

def redirect_with_js(url)
  @redirect_url = url
  render 'shared/redirect.js.erb'
end

private

def valid_otp_attempt?(user)
  user.validate_and_consume_otp!(params[:user][:otp_attempt]) 
end

def prompt_for_otp_two_factor(user)
  @user = user
  @user.generate_two_factor_secret_if_missing!
  @user.enable_two_factor!
  UserMailer.send_otp(@user).deliver_later
  session[:otp_user_id] = user.id
  render 'users/invitations/otp_visible.js.erb'
end

protected

def enable_2fa?
  Subdomain.current.enable_2fa
end

end
  