user = User.create!(
  email: 'violet@rails.com', 
  password: '123456', 
  password_confirmation: '123456', 
  global_admin: true, 
  confirmed_at: Time.now
)
user.update!(User::FULL_PERMISSIONS)
Subdomain.unsafe_bootstrap_www_subdomain
