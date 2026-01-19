Apartment::Tenant.switch!('dsa')
site = Comfy::Cms::Site.first
puts "Site ID: #{site.id}"
puts "Site Label: #{site.label}"
puts "Site Hostname: #{site.hostname}"
puts "Site Path: #{site.path}"
puts ""
puts "Pages:"
site.pages.each do |page|
  puts "  - #{page.slug} (published: #{page.is_published})"
end
puts ""
puts "Total pages: #{site.pages.count}"
