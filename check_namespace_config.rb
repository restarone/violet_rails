Apartment::Tenant.switch!('dsa')
ns = ApiNamespace.first
puts "=" * 70
puts "API Namespace Configuration"
puts "=" * 70
puts "Name: #{ns.name}"
puts "ID: #{ns.id}"
puts "Version: #{ns.version}"
puts "Requires Authentication: #{ns.requires_authentication}"
puts "Namespace Type: #{ns.namespace_type}"
puts "Is Renderable: #{ns.is_renderable}"
puts "Slug: #{ns.slug}"
puts "\n" + "=" * 70
puts "Testing API Endpoint URL"
puts "=" * 70
puts "Expected URL: /api/#{ns.version}/#{ns.slug}"
puts "=" * 70
