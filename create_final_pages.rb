# Create final working DSA pages using client-side rendering
puts "=" * 70
puts "Creating Final DSA Pages with Client-Side Rendering"
puts "=" * 70

Apartment::Tenant.switch!('dsa')

site = Comfy::Cms::Site.first

# Create a layout that loads content dynamically
layout = site.layouts.find_or_initialize_by(identifier: 'dynamic')
layout.label = 'Dynamic Layout'
layout.content = File.read('snippets/dynamic_layout.html')
layout.save!
puts "✓ Created dynamic layout"

# Create pages
pages = {
  'index' => { label: 'Home', script: 'home_page.js' },
  'algorithms' => { label: 'Algorithms', script: 'algorithms_list.js' },
  'algorithms-show' => { label: 'Algorithm Detail', script: 'algorithm_detail.js' },
  'learning-path' => { label: 'Learning Path', script: 'learning_path.js' }
}

pages.each do |slug, config|
  page = site.pages.find_or_initialize_by(slug: slug)
  page.label = config[:label]
  page.layout = layout
  page.is_published = true
  page.save!
  puts "  ✓ Created #{slug}"
end

puts "\n" + "=" * 70
puts "All Pages Created!"
puts "=" * 70
puts "\nYour DSA Directory is ready!"
puts "\nAccess at:"
puts "  http://dsa.localhost:5250/"
puts "  http://dsa.localhost:5250/algorithms"
puts "  http://dsa.localhost:5250/learning-path"
puts "\nOr use Host header:"
puts "  curl -H 'Host: dsa.localhost' http://localhost:5250/"
puts "=" * 70
