# Fix CMS Pages - Simpler approach without complex tags
puts "=" * 70
puts "Fixing DSA CMS Pages"
puts "=" * 70

Apartment::Tenant.switch!('dsa')

site = Comfy::Cms::Site.first
puts "✓ Switched to DSA tenant (#{site.label})"

# Create a simpler layout
layout = site.layouts.find_or_initialize_by(identifier: 'simple')
layout.label = 'Simple Layout'
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
    .footer { background: #2d3748; color: #cbd5e0; padding: 40px 0; margin-top: 60px; }
  </style>
</head>
<body>
  <nav class="navbar navbar-expand-lg navbar-dark mb-4">
    <div class="container">
      <a class="navbar-brand" href="/">🧠 DSA Directory</a>
      <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav">
        <span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="navbarNav">
        <ul class="navbar-nav ml-auto">
          <li class="nav-item"><a class="nav-link" href="/algorithms">All Algorithms</a></li>
          <li class="nav-item"><a class="nav-link" href="/learning-path">Learning Path</a></li>
          <li class="nav-item"><a class="nav-link" href="/admin">Admin</a></li>
        </ul>
      </div>
    </div>
  </nav>
  <main>
    {{ cms:page:content:rich_text }}
  </main>
  <footer class="footer">
    <div class="container text-center">
      <p class="mb-1">&copy; 2025 DSA Directory</p>
      <p class="mb-0"><small>Built with Violet Rails</small></p>
    </div>
  </footer>
  <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
HTML
layout.save!
puts "✓ Created simple layout"

# Update all pages to use simple layout and set content directly
pages_config = {
  'index' => {
    label: 'Home',
    content: File.read('snippets/home_page.html')
  },
  'algorithms' => {
    label: 'Algorithm Directory',
    content: '{{ cms:helper render_api_namespace_resource_index \'algorithms\', order: { priority: \'ASC\' }, snippet: \'algorithms\' }}'
  },
  'algorithms-show' => {
    label: 'Algorithm Detail',
    content: '{{ cms:helper render_api_namespace_resource \'algorithms\', snippet: \'algorithms-show\' }}'
  },
  'learning-path' => {
    label: 'Learning Path',
    content: '{{ cms:helper render_api_namespace_resource_index \'algorithms\', order: { priority: \'ASC\' }, snippet: \'learning-path\' }}'
  }
}

pages_config.each do |slug, config|
  page = site.pages.find_or_initialize_by(slug: slug)
  page.label = config[:label]
  page.layout = layout
  page.is_published = true
  page.save!

  # Set content fragment
  fragment = page.fragments.find_or_initialize_by(identifier: 'content')
  fragment.content = config[:content]
  fragment.save!

  puts "  ✓ Updated page: #{slug}"
end

puts "\n" + "=" * 70
puts "Pages Fixed!"
puts "=" * 70
puts "\nTry accessing:"
puts "  http://dsa.localhost:5250/"
puts "  http://dsa.localhost:5250/algorithms"
puts "  http://dsa.localhost:5250/learning-path"
puts "\n" + "=" * 70
