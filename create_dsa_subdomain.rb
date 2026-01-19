# Create DSA subdomain
subdomain = Subdomain.create!(
  name: 'dsa'
)

puts "DSA subdomain created successfully!"
puts "ID: #{subdomain.id}"
puts "Name: #{subdomain.name}"
puts "Access URL: http://dsa.localhost:5250/admin"
