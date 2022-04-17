Apartment::Tenant.switch('public') do
  User.create!(
    email: 'violet@rails.com', 
    password: '123456', 
    password_confirmation: '123456', 
    global_admin: true, 
    confirmed_at: Time.now,
    can_manage_web: true,
    can_manage_email: true,
    can_manage_users: true,
    can_manage_blog: true
  )
  Subdomain.unsafe_bootstrap_root_domain
  Subdomain.unsafe_bootstrap_www_subdomain
end