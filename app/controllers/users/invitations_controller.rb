class Users::InvitationsController < Devise::InvitationsController
 
include TwofactorAuthenticable

def edit
  session.delete(:otp_user_id)
  super
end

def update 
  self.resource = User.find_by_invitation_token( params[:user][:invitation_token], false)
  if  params[:user][:password].present? &&  params[:user][:password_confirmation] && params[:user][:password] == params[:user][:password_confirmation] && enable_2fa?
    unless session[:otp_user_id]
      generate_and_prompt_for_otp_two_factor(resource)
    else
      if  valid_otp_attempt?(resource)
        session.delete(:otp_user_id)
        new_user
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

end
  