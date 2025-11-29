puts "=" * 70
puts "All Subdomains in the System"
puts "=" * 70

Subdomain.all.each do |subdomain|
  puts "\nSubdomain: #{subdomain.name}"
  puts "  Hostname: #{subdomain.hostname}"
  puts "  ID: #{subdomain.id}"

  # Switch to this tenant and check algorithms
  begin
    Apartment::Tenant.switch!(subdomain.name)
    algo_count = ApiResource.count rescue 0
    namespace_count = ApiNamespace.count rescue 0
    puts "  Algorithms: #{algo_count}"
    puts "  API Namespaces: #{namespace_count}"
  rescue => e
    puts "  Error: #{e.message}"
  end
end

puts "\n" + "=" * 70
puts "Access Instructions:"
puts "=" * 70
Subdomain.all.each do |subdomain|
  puts "\n#{subdomain.name.upcase} Subdomain:"
  puts "  Homepage: http://#{subdomain.hostname}:5250/"
  puts "  Admin: http://#{subdomain.hostname}:5250/admin"
  puts "  Or with curl: curl -H 'Host: #{subdomain.hostname}' http://localhost:5250/"
end
puts "=" * 70
