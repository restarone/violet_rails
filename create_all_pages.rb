# Create all DSA pages with direct HTML content (no CMS helpers that fail)
puts "=" * 70
puts "Creating All DSA Pages"
puts "=" * 70

Apartment::Tenant.switch!('dsa')

site = Comfy::Cms::Site.first
layout = site.layouts.find_by(identifier: 'static')

unless layout
  puts "ERROR: Static layout not found. Run create_static_pages.rb first."
  exit 1
end

puts "✓ Using static layout"

# Read snippet content
algorithms_list_html = File.read('snippets/algorithms_list.html.erb')
algorithm_detail_html = File.read('snippets/algorithm_detail.html.erb')
learning_path_html = File.read('snippets/learning_path.html.erb')
home_html = File.read('snippets/home_page.html')

puts "✓ Loaded all snippets"

# Update layout to include content area properly
layout.content = layout.content.gsub('<main id="content">Loading...</main>', '<main id="dsa-content"></main>')
layout.save!

# Create pages with embedded JavaScript to fetch and render data
pages = [
  {
    slug: 'index',
    label: 'Home',
    html: home_html
  },
  {
    slug: 'algorithms',
    label: 'Algorithms',
    html: <<-HTML
<script>
document.addEventListener('DOMContentLoaded', function() {
  fetch('/api/v1/algorithms.json')
    .then(r => r.json())
    .then(data => {
      document.getElementById('dsa-content').innerHTML = `#{algorithms_list_html.gsub('`', '\`').gsub('#{', '${').gsub('@api_resources', 'data').gsub('@api_namespace', '{slug: "algorithms"}')}`;
    })
    .catch(e => {
      document.getElementById('dsa-content').innerHTML = '<div class="container"><div class="alert alert-warning">Loading algorithms...</div></div>';
      // Fallback: render static snippet
      setTimeout(() => {
        document.getElementById('dsa-content').innerHTML = `#{algorithms_list_html}`;
      }, 1000);
    });
});
</script>
    HTML
  }
]

# For now, let's just create simple pages that work
pages.each do |page_config|
  page = site.pages.find_or_initialize_by(slug: page_config[:slug])
  page.label = page_config[:label]
  page.layout = layout
  page.is_published = true
  page.save!

  # Update layout to inject the HTML content directly
  temp_layout = site.layouts.find_or_initialize_by(identifier: "layout_#{page_config[:slug]}")
  temp_layout.label = "Layout for #{page_config[:label]}"
  temp_layout.content = layout.content.gsub('<main id="dsa-content"></main>', "<main>#{page_config[:html]}</main>")
  temp_layout.save!

  page.layout = temp_layout
  page.save!

  puts "  ✓ Created #{page_config[:slug]}"
end

puts "\n" + "=" * 70
puts "Pages Created!"
puts "=" * 70
puts "\nAccess via:"
puts "  http://dsa.localhost:5250/"
puts "  http://dsa.localhost:5250/algorithms"
puts "=" * 70
