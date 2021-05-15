Apartment::Tenant.switch('public') do
  User.create!(email: 'contact@restarone.com', password: '123456', password_confirmation: '123456', global_admin: true, confirmed_at: Time.now)
  Subdomain.unsafe_bootstrap_www_subdomain
end