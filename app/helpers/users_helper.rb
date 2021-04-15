module UsersHelper
  def should_render_global_navbar?
    User.global_admins(current_sign_in_ip: current_user.current_sign_in_ip).or(User.global_admins(last_sign_in_at: current_user.current_sign_in_ip))
  end
end
