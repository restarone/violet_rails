module UsersHelper
  def should_render_global_navbar?
    User.global_admins(current_sign_in_ip: current_user.current_sign_in_ip).or(User.global_admins(last_sign_in_at: current_user.current_sign_in_ip))
  end

  def render_custom_avatar(user)
    return if !user.avatar.attached?
    image_tag user.avatar, class: 'rounded avatar', size: '40x40'
  end

  def is_last_admin(user)
    User.all.size == 1 || (user.can_manage_users && User.where(can_manage_users: true).size == 1)
  end
end
