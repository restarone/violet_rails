# Create static HTML pages without CMS helpers - direct API access via JavaScript
puts "=" * 70
puts "Creating Static DSA Pages with Direct API Access"
puts "=" * 70

Apartment::Tenant.switch!('dsa')

site = Comfy::Cms::Site.first
puts "✓ Switched to DSA tenant"

# Ultra-simple layout - no CMS tags
layout = site.layouts.find_or_initialize_by(identifier: 'static')
layout.label = 'Static Layout'
layout.content = <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DSA Directory</title>
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
  <style>
    body { background: #f5f7fa; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    .navbar { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .navbar-brand { font-weight: bold; font-size: 1.5em; }
  </style>
</head>
<body>
  <nav class="navbar navbar-expand-lg navbar-dark mb-4">
    <div class="container">
      <a class="navbar-brand" href="/">🧠 DSA Directory</a>
      <div class="collapse navbar-collapse">
        <ul class="navbar-nav ml-auto">
          <li class="nav-item"><a class="nav-link" href="/algorithms">Algorithms</a></li>
          <li class="nav-item"><a class="nav-link" href="/learning-path">Learning Path</a></li>
          <li class="nav-item"><a class="nav-link" href="/admin">Admin</a></li>
        </ul>
      </div>
    </div>
  </nav>
  <main id="content">Loading...</main>
  <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
HTML
layout.save!
puts "✓ Created static layout"

# Create simple test page first
test_page = site.pages.find_or_initialize_by(slug: 'test')
test_page.label = 'Test Page'
test_page.layout = layout
test_page.is_published = true
test_page.save!

puts "✓ Created test page"

puts "\n" + "=" * 70
puts "Test page created!"
puts "=" * 70
puts "\nAccess via:"
puts "  http://dsa.localhost:5250/test"
puts "\nIf this works, we can add the full algorithm pages."
puts "=" * 70
