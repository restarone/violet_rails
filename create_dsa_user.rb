# Create a user for the DSA subdomain
puts "=" * 70
puts "Creating User for DSA Subdomain"
puts "=" * 70

# Switch to DSA tenant
Apartment::Tenant.switch!('dsa')

# Check if user already exists
existing_user = User.find_by(email: 'dsa@rails.com')

if existing_user
  puts "User already exists: dsa@rails.com"
  puts "Updating password..."
  existing_user.password = '123456'
  existing_user.password_confirmation = '123456'
  existing_user.save!
else
  puts "Creating new user..."
  user = User.create!(
    email: 'dsa@rails.com',
    password: '123456',
    password_confirmation: '123456',
    confirmed_at: Time.current
  )
  puts "✓ User created: #{user.email}"
end

puts "\n" + "=" * 70
puts "DSA Subdomain Login Credentials:"
puts "=" * 70
puts "  Email: dsa@rails.com"
puts "  Password: 123456"
puts "\n  Login at: http://dsa.localhost:5250/admin"
puts "=" * 70

# List all API Namespaces
puts "\nAPI Namespaces in DSA:"
ApiNamespace.all.each do |ns|
  puts "  - #{ns.name} (ID: #{ns.id}, #{ns.api_resources.count} resources)"
end

puts "\nTotal Algorithms: #{ApiResource.count}"
puts "=" * 70
