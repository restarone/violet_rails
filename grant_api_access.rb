# Grant API access permissions to DSA user
puts "=" * 70
puts "Granting API Access Permissions to DSA User"
puts "=" * 70

# Switch to DSA tenant
Apartment::Tenant.switch!('dsa')

# Find the user
user = User.find_by(email: 'dsa@rails.com')

if user.nil?
  puts "ERROR: User dsa@rails.com not found"
  exit 1
end

puts "\nCurrent user permissions:"
puts "  Email: #{user.email}"
puts "  API Accessibility: #{user.api_accessibility.inspect}"

# Grant full API access permissions
user.api_accessibility = {
  'api_namespaces' => {
    'all_namespaces' => {
      'full_access' => 'true',
      'full_read_access' => 'true',
      'full_access_api_namespace_only' => 'true',
      'full_access_for_api_resources_only' => 'true',
      'read_api_resources_only' => 'true',
      'delete_access_api_namespace_only' => 'true',
      'delete_access_for_api_resources_only' => 'true',
      'allow_exports' => 'true',
      'allow_duplication' => 'true',
      'allow_social_share_metadata' => 'true',
      'allow_settings' => 'true'
    }
  },
  'api_keys' => {
    'full_access' => 'true',
    'read_access' => 'true',
    'delete_access' => 'true'
  }
}

# Also grant web management permissions
user.can_manage_web = true
user.can_manage_analytics = true
user.can_manage_files = true
user.can_manage_subdomain_settings = true
user.can_manage_users = true

if user.save
  puts "\n✓ Successfully granted permissions!"
  puts "\nUpdated permissions:"
  puts "  API Accessibility: #{user.api_accessibility.inspect}"
  puts "  Can manage web: #{user.can_manage_web}"
  puts "  Can manage analytics: #{user.can_manage_analytics}"
  puts "  Can manage files: #{user.can_manage_files}"
  puts "  Can manage subdomain settings: #{user.can_manage_subdomain_settings}"
  puts "  Can manage users: #{user.can_manage_users}"
else
  puts "\n✗ Failed to save user: #{user.errors.full_messages.join(', ')}"
end

puts "\n" + "=" * 70
puts "User should now have access to /admin/api_namespaces"
puts "=" * 70
