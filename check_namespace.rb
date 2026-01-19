Apartment::Tenant.switch!('dsa')
ns = ApiNamespace.first
puts "Namespace name: #{ns.name}"
puts "Namespace ID: #{ns.id}"
puts "Total resources: #{ns.api_resources.count}"
puts "\nFirst 5 algorithms:"
ns.api_resources.limit(5).each do |resource|
  puts "  - #{resource.properties['name']} (ID: #{resource.id})"
end
