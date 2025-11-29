# Switch to DSA subdomain
Apartment::Tenant.switch!('dsa')

# Get or create the site
site = Comfy::Cms::Site.first_or_create!(
  identifier: 'dsa-site',
  label: 'DSA Directory',
  hostname: 'dsa.localhost'
)

puts "Site created/found: #{site.label} (ID: #{site.id})"

# Create default layout if it doesn't exist
layout = site.layouts.first_or_create!(
  identifier: 'default',
  label: 'Default Layout',
  content: <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>{{ cms:page:title:string }}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
  <style>
    body { padding-top: 20px; }
    .algorithm-card { transition: transform 0.2s, box-shadow 0.2s; }
    .algorithm-card:hover { transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
  </style>
</head>
<body>
  <nav class="navbar navbar-expand-lg navbar-dark bg-primary mb-4">
    <div class="container">
      <a class="navbar-brand" href="/">DSA Directory</a>
      <div class="navbar-nav ml-auto">
        <a class="nav-link" href="/algorithms">All Algorithms</a>
        <a class="nav-link" href="/learning-path">Learning Path</a>
        <a class="nav-link" href="/admin">Admin</a>
      </div>
    </div>
  </nav>

  <div class="container">
    {{ cms:page:content:rich_text }}
  </div>

  <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
HTML
)

puts "Layout created/found: #{layout.label}"

# Create Algorithm Directory Page
algorithms_page = site.pages.find_or_initialize_by(slug: 'algorithms')
algorithms_page.label = 'Algorithm Directory'
algorithms_page.layout = layout
algorithms_page.is_published = true

# Create fragments for the page
algorithms_page.save!

# Set the content
content_fragment = algorithms_page.fragments.find_or_initialize_by(identifier: 'content')
content_fragment.tag = 'rich_text'
content_fragment.content = <<-HTML
<h1 class="mb-4">DSA Learning Directory</h1>

<div class="row mb-4">
  <div class="col-md-12">
    <p class="lead">
      Master 30 essential data structures and algorithms through a progressive 7-phase learning path.
    </p>
  </div>
</div>

<div class="row mb-4">
  <div class="col-md-3">
    <label for="difficulty-filter">Difficulty:</label>
    <select id="difficulty-filter" class="form-control">
      <option value="">All</option>
      <option value="Easy">Easy</option>
      <option value="Medium">Medium</option>
      <option value="Hard">Hard</option>
    </select>
  </div>

  <div class="col-md-3">
    <label for="phase-filter">Learning Phase:</label>
    <select id="phase-filter" class="form-control">
      <option value="">All Phases</option>
      <option value="1">Phase 1: Foundation</option>
      <option value="2">Phase 2: Core Patterns</option>
      <option value="3">Phase 3: Stack Mastery</option>
      <option value="4">Phase 4: Binary Search</option>
      <option value="5">Phase 5: Dynamic Programming</option>
      <option value="6">Phase 6: Advanced Structures</option>
      <option value="7">Phase 7: Complex Algorithms</option>
    </select>
  </div>

  <div class="col-md-3">
    <label for="search">Search:</label>
    <input type="text" id="search" class="form-control" placeholder="Search algorithms...">
  </div>

  <div class="col-md-3">
    <label>&nbsp;</label>
    <button id="reset-filters" class="btn btn-secondary btn-block">Reset Filters</button>
  </div>
</div>

<div id="algorithm-grid" class="row">
  <div class="col-md-12">
    <div id="loading" class="text-center my-5">
      <div class="spinner-border text-primary" role="status">
        <span class="sr-only">Loading...</span>
      </div>
      <p class="mt-2">Loading algorithms...</p>
    </div>
    <div id="algorithms-list" style="display: none;"></div>
  </div>
</div>

<script>
let allAlgorithms = [];

async function loadAlgorithms() {
  try {
    const response = await fetch('/api_namespaces/algorithms/api_resources.json');
    const data = await response.json();
    allAlgorithms = data;

    document.getElementById('loading').style.display = 'none';
    document.getElementById('algorithms-list').style.display = 'block';

    renderAlgorithms(allAlgorithms);
  } catch (error) {
    console.error('Error loading algorithms:', error);
    document.getElementById('loading').innerHTML =
      '<div class="alert alert-danger">Error loading algorithms. Please refresh the page.</div>';
  }
}

function renderAlgorithms(algorithms) {
  const container = document.getElementById('algorithms-list');

  if (!algorithms || algorithms.length === 0) {
    container.innerHTML = '<div class="alert alert-info">No algorithms found.</div>';
    return;
  }

  const sorted = algorithms.sort((a, b) => {
    const prioA = a.properties?.priority || 999;
    const prioB = b.properties?.priority || 999;
    return prioA - prioB;
  });

  const html = sorted.map(algo => {
    const props = algo.properties || {};
    const difficulty = props.difficulty || 'Unknown';
    const badgeClass = difficulty === 'Easy' ? 'success' : difficulty === 'Medium' ? 'warning' : 'danger';

    return `
      <div class="card mb-3 algorithm-card"
           data-difficulty="${difficulty}"
           data-phase="${props.learning_phase || ''}"
           data-name="${(props.name || '').toLowerCase()}">
        <div class="card-body">
          <div class="row">
            <div class="col-md-8">
              <h5 class="card-title">
                ${props.name || 'Untitled'}
                <span class="badge badge-${badgeClass} ml-2">${difficulty}</span>
                <span class="badge badge-secondary ml-1">Phase ${props.learning_phase || '?'}</span>
              </h5>
              <p class="card-text text-muted">${props.real_world_analogy || 'No description available'}</p>
              <small class="text-muted">
                <strong>Data Structure:</strong> ${props.primary_data_structure || 'N/A'}
              </small>
            </div>
            <div class="col-md-4 text-right">
              <div><strong>Time:</strong> ${props.time_complexity || 'N/A'}</div>
              <div><strong>Space:</strong> ${props.space_complexity || 'N/A'}</div>
              <div class="mt-2">
                <a href="/api_namespaces/algorithms/api_resources/${algo.id}" class="btn btn-sm btn-primary">View Details</a>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }).join('');

  container.innerHTML = html;
  updateCount();
}

function filterAlgorithms() {
  const difficulty = document.getElementById('difficulty-filter').value;
  const phase = document.getElementById('phase-filter').value;
  const search = document.getElementById('search').value.toLowerCase();

  const cards = document.querySelectorAll('.algorithm-card');

  cards.forEach(card => {
    let show = true;

    if (difficulty && card.dataset.difficulty !== difficulty) show = false;
    if (phase && card.dataset.phase !== phase) show = false;
    if (search && !card.dataset.name.includes(search)) show = false;

    card.style.display = show ? 'block' : 'none';
  });

  updateCount();
}

function updateCount() {
  const visible = document.querySelectorAll('.algorithm-card[style="display: block;"], .algorithm-card:not([style*="display"])').length;
  const total = allAlgorithms.length;

  // You could add a count display here if desired
}

function resetFilters() {
  document.getElementById('difficulty-filter').value = '';
  document.getElementById('phase-filter').value = '';
  document.getElementById('search').value = '';
  filterAlgorithms();
}

// Event listeners
document.getElementById('difficulty-filter').addEventListener('change', filterAlgorithms);
document.getElementById('phase-filter').addEventListener('change', filterAlgorithms);
document.getElementById('search').addEventListener('input', filterAlgorithms);
document.getElementById('reset-filters').addEventListener('click', resetFilters);

// Load on page ready
document.addEventListener('DOMContentLoaded', loadAlgorithms);
</script>
HTML

content_fragment.save!

title_fragment = algorithms_page.fragments.find_or_initialize_by(identifier: 'title')
title_fragment.tag = 'string'
title_fragment.content = 'Algorithm Directory'
title_fragment.save!

algorithms_page.save!

puts "✓ Algorithm Directory page created at: /algorithms"

# Create Home Page
home_page = site.pages.find_or_initialize_by(full_path: '/')
home_page.label = 'Home'
home_page.slug = 'index'
home_page.layout = layout
home_page.is_published = true
home_page.save!

home_content = home_page.fragments.find_or_initialize_by(identifier: 'content')
home_content.tag = 'rich_text'
home_content.content = <<-HTML
<div class="jumbotron text-center">
  <h1 class="display-4">DSA Learning Directory</h1>
  <p class="lead">Master Data Structures & Algorithms Through Progressive Learning</p>
  <hr class="my-4">
  <p>30 carefully curated algorithms across 7 learning phases, designed with instructional best practices.</p>
  <a class="btn btn-primary btn-lg" href="/algorithms" role="button">Explore Algorithms</a>
  <a class="btn btn-outline-primary btn-lg ml-2" href="/learning-path" role="button">View Learning Path</a>
</div>

<div class="row">
  <div class="col-md-4">
    <div class="card">
      <div class="card-body text-center">
        <h3>30</h3>
        <p class="text-muted">Essential Algorithms</p>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card">
      <div class="card-body text-center">
        <h3>7</h3>
        <p class="text-muted">Learning Phases</p>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card">
      <div class="card-body text-center">
        <h3>∞</h3>
        <p class="text-muted">Learning Opportunities</p>
      </div>
    </div>
  </div>
</div>

<div class="row mt-5">
  <div class="col-md-12">
    <h2 class="mb-4">Learning Phases</h2>
  </div>

  <div class="col-md-6 mb-3">
    <div class="card border-success">
      <div class="card-header bg-success text-white">Phase 1: Foundation Patterns</div>
      <div class="card-body">
        <p>Build core skills with array manipulation and simple data structures. Start your journey here!</p>
        <small class="text-muted">5 algorithms • Easy to Medium difficulty</small>
      </div>
    </div>
  </div>

  <div class="col-md-6 mb-3">
    <div class="card border-info">
      <div class="card-header bg-info text-white">Phase 2: Core Patterns</div>
      <div class="card-body">
        <p>Master essential algorithmic patterns that appear repeatedly in coding challenges.</p>
        <small class="text-muted">5 algorithms • Medium difficulty</small>
      </div>
    </div>
  </div>

  <div class="col-md-6 mb-3">
    <div class="card border-primary">
      <div class="card-header bg-primary text-white">Phase 3: Stack Mastery</div>
      <div class="card-body">
        <p>Deep dive into stack-based problem solving and recursive thinking.</p>
        <small class="text-muted">3 algorithms • Medium to Hard difficulty</small>
      </div>
    </div>
  </div>

  <div class="col-md-6 mb-3">
    <div class="card border-warning">
      <div class="card-header bg-warning">Phase 4: Binary Search</div>
      <div class="card-body">
        <p>Optimize your search skills with binary search techniques and variations.</p>
        <small class="text-muted">3 algorithms • Medium to Hard difficulty</small>
      </div>
    </div>
  </div>

  <div class="col-md-6 mb-3">
    <div class="card border-danger">
      <div class="card-header bg-danger text-white">Phase 5: Dynamic Programming</div>
      <div class="card-body">
        <p>Unlock the power of memoization and tabulation for complex problems.</p>
        <small class="text-muted">4 algorithms • Medium difficulty</small>
      </div>
    </div>
  </div>

  <div class="col-md-6 mb-3">
    <div class="card border-secondary">
      <div class="card-header bg-secondary text-white">Phase 6: Advanced Structures</div>
      <div class="card-body">
        <p>Work with linked lists, heaps, caches, and other advanced data structures.</p>
        <small class="text-muted">4 algorithms • Medium difficulty</small>
      </div>
    </div>
  </div>

  <div class="col-md-12 mb-3">
    <div class="card border-dark">
      <div class="card-header bg-dark text-white">Phase 7: Complex Algorithms</div>
      <div class="card-body">
        <p>Tackle multi-dimensional problems, graph algorithms, and advanced techniques.</p>
        <small class="text-muted">6 algorithms • Medium to Hard difficulty</small>
      </div>
    </div>
  </div>
</div>
HTML
home_content.save!

home_title = home_page.fragments.find_or_initialize_by(identifier: 'title')
home_title.tag = 'string'
home_title.content = 'Home - DSA Directory'
home_title.save!

home_page.save!

puts "✓ Home page created at: /"

puts "\n" + "="*60
puts "SUCCESS! CMS Pages Created"
puts "="*60
puts "\nVisit these URLs:"
puts "  Home: http://dsa.localhost:5250/"
puts "  Algorithms: http://dsa.localhost:5250/algorithms"
puts "  Admin: http://dsa.localhost:5250/admin"
puts "\n" + "="*60
