# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Apartment::Tenant.switch('public') do
  User.create!(email: 'contact@restarone.com', password: '123456', password_confirmation: '123456', global_admin: true, confirmed_at: Time.now)
end