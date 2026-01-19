# Setup DSA UI - Creates all CMS pages and snippets for the DSA Directory
puts "=" * 70
puts "DSA Directory UI Setup"
puts "=" * 70

# Switch to DSA tenant
begin
  Apartment::Tenant.switch!('dsa')
  puts "✓ Switched to DSA tenant"
rescue Apartment::TenantNotFound
  puts "✗ ERROR: DSA subdomain not found. Please create it first."
  exit 1
end

# Get the site
site = Comfy::Cms::Site.first
unless site
  puts "✗ ERROR: No CMS site found"
  exit 1
end
puts "✓ Found CMS site: #{site.label}"

# Get or create default layout
puts "\nSetting up layout..."
layout = site.layouts.find_or_initialize_by(identifier: 'default')
layout.label = 'Default Layout'
layout.content = <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{ cms:page:title:string }} - DSA Directory</title>

  <!-- Bootstrap 4 CSS -->
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">

  <!-- Custom CSS -->
  <style>
    body {
      background: #f5f7fa;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    }
    .navbar {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .navbar-brand {
      font-weight: bold;
      font-size: 1.5em;
    }
    .footer {
      background: #2d3748;
      color: #cbd5e0;
      padding: 40px 0;
      margin-top: 60px;
    }
  </style>

  {{ cms:page:css:text }}
</head>
<body>
  <!-- Navigation -->
  <nav class="navbar navbar-expand-lg navbar-dark mb-4">
    <div class="container">
      <a class="navbar-brand" href="/">🧠 DSA Directory</a>
      <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav">
        <span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="navbarNav">
        <ul class="navbar-nav ml-auto">
          <li class="nav-item">
            <a class="nav-link" href="/algorithms">All Algorithms</a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="/learning-path">Learning Path</a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="/admin">Admin</a>
          </li>
        </ul>
      </div>
    </div>
  </nav>

  <!-- Main Content -->
  <main>
    {{ cms:page:content:rich_text }}
  </main>

  <!-- Footer -->
  <footer class="footer">
    <div class="container text-center">
      <p class="mb-1">&copy; 2025 DSA Directory - Master Data Structures & Algorithms</p>
      <p class="mb-0">
        <small>Built with Violet Rails • 30 Essential Algorithms • 7 Learning Phases</small>
      </p>
    </div>
  </footer>

  <!-- Bootstrap JS -->
  <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.2/dist/js/bootstrap.bundle.min.js"></script>

  {{ cms:page:js:text }}
</body>
</html>
HTML
layout.save!
puts "✓ Layout configured"

# Load snippet content from files
puts "\nCreating snippets..."

snippet_files = {
  'algorithms' => 'snippets/algorithms_list.html.erb',
  'algorithms-show' => 'snippets/algorithm_detail.html.erb',
  'learning-path' => 'snippets/learning_path.html.erb'
}

snippet_files.each do |identifier, file_path|
  content = File.read(file_path)

  snippet = site.snippets.find_or_initialize_by(identifier: identifier)
  snippet.label = identifier.split('-').map(&:capitalize).join(' ')
  snippet.content = content
  snippet.save!

  puts "  ✓ Created snippet: #{snippet.label}"
end

# Create Pages
puts "\nCreating pages..."

# 1. Algorithms Index Page
algorithms_page = site.pages.find_or_initialize_by(slug: 'algorithms')
algorithms_page.label = 'Algorithm Directory'
algorithms_page.layout = layout
algorithms_page.is_published = true
algorithms_page.save!

title_fragment = algorithms_page.fragments.find_or_initialize_by(identifier: 'title')
title_fragment.tag = 'string'
title_fragment.content = 'Algorithm Directory'
title_fragment.save!

content_fragment = algorithms_page.fragments.find_or_initialize_by(identifier: 'content')
content_fragment.tag = 'rich_text'
content_fragment.content = <<-HTML
{{ cms:helper render_api_namespace_resource_index 'algorithms', order: { priority: 'ASC' }, snippet: 'algorithms' }}
HTML
content_fragment.save!

puts "  ✓ Created page: #{algorithms_page.slug}"

# 2. Algorithm Detail Page
detail_page = site.pages.find_or_initialize_by(slug: 'algorithms-show')
detail_page.label = 'Algorithm Detail'
detail_page.layout = layout
detail_page.is_published = true
detail_page.save!

title_fragment = detail_page.fragments.find_or_initialize_by(identifier: 'title')
title_fragment.tag = 'string'
title_fragment.content = 'Algorithm Details'
title_fragment.save!

content_fragment = detail_page.fragments.find_or_initialize_by(identifier: 'content')
content_fragment.tag = 'rich_text'
content_fragment.content = <<-HTML
{{ cms:helper render_api_namespace_resource 'algorithms', snippet: 'algorithms-show' }}
HTML
content_fragment.save!

puts "  ✓ Created page: #{detail_page.slug}"

# 3. Learning Path Page
path_page = site.pages.find_or_initialize_by(slug: 'learning-path')
path_page.label = 'Learning Path'
path_page.layout = layout
path_page.is_published = true
path_page.save!

title_fragment = path_page.fragments.find_or_initialize_by(identifier: 'title')
title_fragment.tag = 'string'
title_fragment.content = 'DSA Learning Path'
title_fragment.save!

content_fragment = path_page.fragments.find_or_initialize_by(identifier: 'content')
content_fragment.tag = 'rich_text'
content_fragment.content = <<-HTML
{{ cms:helper render_api_namespace_resource_index 'algorithms', order: { priority: 'ASC' }, snippet: 'learning-path' }}
HTML
content_fragment.save!

puts "  ✓ Created page: #{path_page.slug}"

# 4. Create Home Page (redirects to algorithms)
home_page = site.pages.find_or_initialize_by(slug: 'index')
home_page.label = 'Home'
home_page.layout = layout
home_page.is_published = true
home_page.save!

title_fragment = home_page.fragments.find_or_initialize_by(identifier: 'title')
title_fragment.tag = 'string'
title_fragment.content = 'DSA Directory'
title_fragment.save!

content_fragment = home_page.fragments.find_or_initialize_by(identifier: 'content')
content_fragment.tag = 'rich_text'
content_fragment.content = <<-HTML
<div class="container">
  <div class="jumbotron mt-5" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
    <h1 class="display-3">🧠 DSA Directory</h1>
    <p class="lead">Master 30 essential Data Structures & Algorithms across 7 progressive learning phases</p>
    <hr class="my-4" style="border-color: rgba(255,255,255,0.3);">
    <p>Build a strong foundation in algorithmic thinking with carefully curated problems, real-world analogies, and structured learning paths.</p>
    <p class="lead mt-4">
      <a class="btn btn-light btn-lg mr-3" href="/algorithms" role="button">Browse Algorithms →</a>
      <a class="btn btn-outline-light btn-lg" href="/learning-path" role="button">View Learning Path</a>
    </p>
  </div>

  <div class="row mt-5 mb-5">
    <div class="col-md-4 text-center mb-4">
      <div class="card h-100">
        <div class="card-body">
          <h2 style="font-size: 3em;">30</h2>
          <h5>Essential Algorithms</h5>
          <p class="text-muted">Carefully selected problems covering all major patterns</p>
        </div>
      </div>
    </div>
    <div class="col-md-4 text-center mb-4">
      <div class="card h-100">
        <div class="card-body">
          <h2 style="font-size: 3em;">7</h2>
          <h5>Learning Phases</h5>
          <p class="text-muted">Progressive difficulty from foundation to mastery</p>
        </div>
      </div>
    </div>
    <div class="col-md-4 text-center mb-4">
      <div class="card h-100">
        <div class="card-body">
          <h2 style="font-size: 3em;">3</h2>
          <h5>Difficulty Levels</h5>
          <p class="text-muted">Easy, Medium, and Hard problems for all skill levels</p>
        </div>
      </div>
    </div>
  </div>

  <div class="row mb-5">
    <div class="col-md-6">
      <h3>📚 What You'll Find</h3>
      <ul>
        <li>Real-world analogies for every algorithm</li>
        <li>Complexity analysis (time & space)</li>
        <li>Learning objectives and key insights</li>
        <li>Practice challenges and related problems</li>
        <li>Visual elements and walkthroughs</li>
        <li>Progress tracking and study lists</li>
      </ul>
    </div>
    <div class="col-md-6">
      <h3>🎯 Learning Phases</h3>
      <ol>
        <li><strong>Foundation Patterns</strong> - Arrays & basics</li>
        <li><strong>Core Patterns</strong> - Essential techniques</li>
        <li><strong>Stack Mastery</strong> - Stack-based solving</li>
        <li><strong>Binary Search</strong> - Search optimization</li>
        <li><strong>Dynamic Programming</strong> - Memoization</li>
        <li><strong>Advanced Structures</strong> - Heaps & more</li>
        <li><strong>Complex Algorithms</strong> - Graphs & 2D</li>
      </ol>
    </div>
  </div>
</div>
HTML
content_fragment.save!

puts "  ✓ Created page: #{home_page.slug}"

# Summary
puts "\n" + "=" * 70
puts "Setup Complete!"
puts "=" * 70

puts "\nPages Created:"
puts "  • Home:              http://dsa.localhost:5250/"
puts "  • Algorithm List:    http://dsa.localhost:5250/algorithms"
puts "  • Algorithm Detail:  http://dsa.localhost:5250/algorithms-show?id=<ID>"
puts "  • Learning Path:     http://dsa.localhost:5250/learning-path"

puts "\nSnippets Created:"
snippet_files.each do |identifier, _|
  puts "  • #{identifier}"
end

puts "\nNext Steps:"
puts "  1. Visit http://dsa.localhost:5250/ to see your DSA directory"
puts "  2. Browse all #{ApiResource.count} algorithms"
puts "  3. Track your progress through the learning path"
puts "  4. Customize pages via Admin panel if needed"

puts "\n" + "=" * 70
