# CMS Page Templates for DSA Directory

These templates can be used to create custom CMS pages in Violet Rails for the DSA Directory.

## Page 1: Algorithm Directory (`/algorithms`)

**Page Settings:**
- Label: Algorithm Directory
- Slug: `algorithms`
- Layout: Default

**Content (HTML/Liquid):**

```liquid
<div class="container mt-5">
  <h1 class="mb-4">DSA Learning Directory</h1>

  <div class="row mb-4">
    <div class="col-md-12">
      <p class="lead">
        Master 30 essential data structures and algorithms through a progressive 7-phase learning path.
      </p>
    </div>
  </div>

  <!-- Filter Controls -->
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
      <label for="data-structure-filter">Data Structure:</label>
      <select id="data-structure-filter" class="form-control">
        <option value="">All</option>
        <option value="Arrays">Arrays</option>
        <option value="Hash">Hash Map</option>
        <option value="Stack">Stack</option>
        <option value="Linked">Linked List</option>
        <option value="Tree">Tree</option>
        <option value="Graph">Graph</option>
      </select>
    </div>

    <div class="col-md-3">
      <label for="sort-by">Sort By:</label>
      <select id="sort-by" class="form-control">
        <option value="priority">Priority</option>
        <option value="difficulty">Difficulty</option>
        <option value="problem_number">Problem Number</option>
      </select>
    </div>
  </div>

  <!-- Algorithm Grid -->
  <div id="algorithm-grid" class="row">
    {% comment %}
    This section should fetch from API Namespace 'algorithms'
    For now, use a placeholder API call or manual rendering
    {% endcomment %}

    <div class="col-md-12">
      <div id="algorithms-list">
        <!-- Algorithms will be loaded here via JavaScript -->
        <p class="text-muted">Loading algorithms...</p>
      </div>
    </div>
  </div>
</div>

<script>
// Fetch algorithms from API
async function loadAlgorithms() {
  try {
    // Adjust endpoint based on your Violet Rails API configuration
    const response = await fetch('/api/v1/algorithms');
    const data = await response.json();

    renderAlgorithms(data);
  } catch (error) {
    console.error('Error loading algorithms:', error);
    document.getElementById('algorithms-list').innerHTML =
      '<p class="text-danger">Error loading algorithms. Please try again.</p>';
  }
}

function renderAlgorithms(algorithms) {
  const container = document.getElementById('algorithms-list');

  if (!algorithms || algorithms.length === 0) {
    container.innerHTML = '<p class="text-muted">No algorithms found.</p>';
    return;
  }

  const html = algorithms.map(algo => `
    <div class="card mb-3 algorithm-card"
         data-difficulty="${algo.difficulty}"
         data-phase="${algo.learning_phase}"
         data-structure="${algo.primary_data_structure}">
      <div class="card-body">
        <div class="row">
          <div class="col-md-8">
            <h5 class="card-title">
              <a href="/algorithms/${algo.id}">${algo.name}</a>
              <span class="badge badge-${algo.difficulty === 'Easy' ? 'success' : algo.difficulty === 'Medium' ? 'warning' : 'danger'} ml-2">
                ${algo.difficulty}
              </span>
            </h5>
            <p class="card-text text-muted">${algo.real_world_analogy || 'No analogy available'}</p>
          </div>
          <div class="col-md-4 text-right">
            <div><strong>Phase:</strong> ${algo.learning_phase}</div>
            <div><strong>Time:</strong> ${algo.time_complexity}</div>
            <div><strong>Space:</strong> ${algo.space_complexity}</div>
          </div>
        </div>
      </div>
    </div>
  `).join('');

  container.innerHTML = html;
}

// Filter functionality
function filterAlgorithms() {
  const difficulty = document.getElementById('difficulty-filter').value;
  const phase = document.getElementById('phase-filter').value;
  const dataStructure = document.getElementById('data-structure-filter').value;

  const cards = document.querySelectorAll('.algorithm-card');

  cards.forEach(card => {
    let show = true;

    if (difficulty && card.dataset.difficulty !== difficulty) show = false;
    if (phase && card.dataset.phase !== phase) show = false;
    if (dataStructure && !card.dataset.structure.includes(dataStructure)) show = false;

    card.style.display = show ? 'block' : 'none';
  });
}

// Event listeners
document.getElementById('difficulty-filter').addEventListener('change', filterAlgorithms);
document.getElementById('phase-filter').addEventListener('change', filterAlgorithms);
document.getElementById('data-structure-filter').addEventListener('change', filterAlgorithms);

// Load on page ready
document.addEventListener('DOMContentLoaded', loadAlgorithms);
</script>

<style>
.algorithm-card {
  transition: transform 0.2s, box-shadow 0.2s;
}

.algorithm-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.badge {
  font-size: 0.75rem;
  padding: 0.25rem 0.5rem;
}
</style>
```

---

## Page 2: Algorithm Detail (`/algorithms/:id`)

**Page Settings:**
- Label: Algorithm Detail
- Slug: `algorithm-detail` (or use dynamic routing)

**Content (HTML/Liquid):**

```liquid
<div class="container mt-5">
  <!-- Breadcrumb -->
  <nav aria-label="breadcrumb">
    <ol class="breadcrumb">
      <li class="breadcrumb-item"><a href="/">Home</a></li>
      <li class="breadcrumb-item"><a href="/algorithms">Algorithms</a></li>
      <li class="breadcrumb-item active" aria-current="page" id="algo-name">Loading...</li>
    </ol>
  </nav>

  <!-- Algorithm Header -->
  <div class="row mb-4">
    <div class="col-md-8">
      <h1 id="algorithm-title">Loading...</h1>
      <div id="algorithm-badges" class="mb-3">
        <!-- Badges will be inserted here -->
      </div>
    </div>
    <div class="col-md-4 text-right">
      <div class="card bg-light">
        <div class="card-body">
          <h6>Quick Stats</h6>
          <div><strong>Phase:</strong> <span id="phase"></span></div>
          <div><strong>Time:</strong> <span id="time-complexity"></span></div>
          <div><strong>Space:</strong> <span id="space-complexity"></span></div>
          <div><strong>Priority:</strong> <span id="priority"></span></div>
        </div>
      </div>
    </div>
  </div>

  <!-- Problem Hook -->
  <div class="card mb-4 border-primary">
    <div class="card-header bg-primary text-white">
      <h4 id="hook-title">Problem Hook</h4>
    </div>
    <div class="card-body">
      <p id="hook-analogy" class="lead"></p>
    </div>
  </div>

  <!-- Learning Objective -->
  <div class="alert alert-info" role="alert">
    <h5>Learning Objective</h5>
    <p id="learning-objective" class="mb-0"></p>
  </div>

  <!-- Algorithm Walkthrough -->
  <div class="card mb-4">
    <div class="card-header">
      <h4>Algorithm Walkthrough</h4>
    </div>
    <div class="card-body">
      <div id="walkthrough-content">
        <!-- Rich text content will be inserted here -->
      </div>
    </div>
  </div>

  <!-- Visual/Animation -->
  <div class="card mb-4" id="visual-section" style="display: none;">
    <div class="card-header">
      <h4>Visual Explanation</h4>
    </div>
    <div class="card-body">
      <div id="visual-container">
        <!-- Embed or iframe for visualization -->
      </div>
    </div>
  </div>

  <!-- Key Insights -->
  <div class="card mb-4 border-success">
    <div class="card-header bg-success text-white">
      <h4>Key Insights</h4>
    </div>
    <div class="card-body">
      <div id="key-insights"></div>
    </div>
  </div>

  <!-- Practice Challenge -->
  <div class="card mb-4 border-warning">
    <div class="card-header bg-warning">
      <h4>Practice Challenge</h4>
    </div>
    <div class="card-body">
      <p id="practice-challenge"></p>
    </div>
  </div>

  <!-- Related Algorithms -->
  <div class="card mb-4">
    <div class="card-header">
      <h4>Related Algorithms</h4>
    </div>
    <div class="card-body">
      <div id="related-algorithms"></div>
    </div>
  </div>

  <!-- Navigation -->
  <div class="row mt-4">
    <div class="col-md-6">
      <a href="/algorithms" class="btn btn-secondary">&larr; Back to Directory</a>
    </div>
    <div class="col-md-6 text-right">
      <a href="/learning-path" class="btn btn-primary">View Learning Path &rarr;</a>
    </div>
  </div>
</div>

<script>
async function loadAlgorithm() {
  // Get algorithm ID from URL or parameter
  const urlParams = new URLSearchParams(window.location.search);
  const algoId = urlParams.get('id') || window.location.pathname.split('/').pop();

  try {
    const response = await fetch(`/api/v1/algorithms/${algoId}`);
    const algo = await response.json();

    // Populate all fields
    document.getElementById('algo-name').textContent = algo.name;
    document.getElementById('algorithm-title').textContent = algo.name;

    // Badges
    const badgesHtml = `
      <span class="badge badge-${algo.difficulty === 'Easy' ? 'success' : algo.difficulty === 'Medium' ? 'warning' : 'danger'}">
        ${algo.difficulty}
      </span>
      <span class="badge badge-info">${algo.primary_data_structure}</span>
      <span class="badge badge-secondary">Phase ${algo.learning_phase}</span>
    `;
    document.getElementById('algorithm-badges').innerHTML = badgesHtml;

    // Quick stats
    document.getElementById('phase').textContent = algo.learning_phase;
    document.getElementById('time-complexity').textContent = algo.time_complexity;
    document.getElementById('space-complexity').textContent = algo.space_complexity;
    document.getElementById('priority').textContent = algo.priority;

    // Problem hook
    document.getElementById('hook-title').textContent = algo.problem_hook_title || 'Problem Hook';
    document.getElementById('hook-analogy').textContent = algo.problem_hook_analogy || 'No analogy available.';

    // Learning objective
    document.getElementById('learning-objective').textContent = algo.learning_objective || 'No learning objective specified.';

    // Walkthrough
    document.getElementById('walkthrough-content').innerHTML = algo.walkthrough_content || '<p>Content coming soon...</p>';

    // Visual
    if (algo.visual_url) {
      document.getElementById('visual-section').style.display = 'block';
      document.getElementById('visual-container').innerHTML =
        `<iframe src="${algo.visual_url}" width="100%" height="500" frameborder="0"></iframe>`;
    }

    // Key insights
    document.getElementById('key-insights').innerHTML =
      `<p>${algo.key_insights || 'No insights available yet.'}</p>`;

    // Practice challenge
    document.getElementById('practice-challenge').textContent =
      algo.practice_challenge || 'No practice challenge available.';

    // Related algorithms
    document.getElementById('related-algorithms').innerHTML =
      `<p>${algo.related_algorithms || 'No related algorithms listed.'}</p>`;

  } catch (error) {
    console.error('Error loading algorithm:', error);
    document.querySelector('.container').innerHTML =
      '<div class="alert alert-danger">Error loading algorithm. Please try again.</div>';
  }
}

document.addEventListener('DOMContentLoaded', loadAlgorithm);
</script>
```

---

## Page 3: Learning Path Tracker (`/learning-path`)

**Page Settings:**
- Label: Learning Path
- Slug: `learning-path`

**Content (HTML/Liquid):**

```liquid
<div class="container mt-5">
  <h1 class="mb-4">Your Learning Path</h1>

  <div class="row mb-4">
    <div class="col-md-12">
      <p class="lead">
        Progress through 7 phases of mastery, from foundation patterns to complex algorithms.
      </p>

      <!-- Overall Progress -->
      <div class="card mb-4">
        <div class="card-body">
          <h5>Overall Progress</h5>
          <div class="progress" style="height: 30px;">
            <div id="overall-progress" class="progress-bar" role="progressbar" style="width: 0%;" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100">
              <span id="progress-text">0 / 30</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Learning Phases -->
  <div id="learning-phases">
    <!-- Phases will be dynamically loaded here -->
  </div>
</div>

<script>
const PHASE_INFO = [
  { phase: 1, name: 'Foundation Patterns', description: 'Basic array manipulation and simple data structures', color: '#28a745' },
  { phase: 2, name: 'Core Patterns', description: 'Essential algorithmic patterns', color: '#17a2b8' },
  { phase: 3, name: 'Stack Mastery', description: 'Stack-based problem solving', color: '#6f42c1' },
  { phase: 4, name: 'Binary Search', description: 'Search optimization techniques', color: '#fd7e14' },
  { phase: 5, name: 'Dynamic Programming', description: 'Memoization and tabulation', color: '#dc3545' },
  { phase: 6, name: 'Advanced Structures', description: 'Linked lists, heaps, LRU cache', color: '#e83e8c' },
  { phase: 7, name: 'Complex Algorithms', description: 'Multi-dimensional and graph problems', color: '#6c757d' }
];

async function loadLearningPath() {
  try {
    const response = await fetch('/api/v1/algorithms');
    const algorithms = await response.json();

    // Group by phase
    const phaseGroups = {};
    PHASE_INFO.forEach(phase => {
      phaseGroups[phase.phase] = algorithms.filter(a => a.learning_phase === phase.phase);
    });

    // Render phases
    const phasesContainer = document.getElementById('learning-phases');

    PHASE_INFO.forEach(phaseInfo => {
      const phaseAlgos = phaseGroups[phaseInfo.phase] || [];
      const completed = phaseAlgos.filter(a => isCompleted(a.id)).length;
      const total = phaseAlgos.length;
      const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;

      const phaseHtml = `
        <div class="card mb-4">
          <div class="card-header" style="background-color: ${phaseInfo.color}; color: white;">
            <h4>Phase ${phaseInfo.phase}: ${phaseInfo.name}</h4>
            <p class="mb-0">${phaseInfo.description}</p>
          </div>
          <div class="card-body">
            <div class="progress mb-3" style="height: 20px;">
              <div class="progress-bar" style="width: ${percentage}%; background-color: ${phaseInfo.color};">
                ${completed} / ${total}
              </div>
            </div>

            <div class="list-group">
              ${phaseAlgos.map(algo => `
                <div class="list-group-item d-flex justify-content-between align-items-center">
                  <div class="form-check">
                    <input class="form-check-input algorithm-checkbox" type="checkbox"
                           id="algo-${algo.id}" data-algo-id="${algo.id}"
                           ${isCompleted(algo.id) ? 'checked' : ''}>
                    <label class="form-check-label" for="algo-${algo.id}">
                      <a href="/algorithms/${algo.id}">${algo.name}</a>
                      <span class="badge badge-${algo.difficulty === 'Easy' ? 'success' : algo.difficulty === 'Medium' ? 'warning' : 'danger'} ml-2">
                        ${algo.difficulty}
                      </span>
                    </label>
                  </div>
                  <small class="text-muted">${algo.time_complexity}</small>
                </div>
              `).join('')}
            </div>
          </div>
        </div>
      `;

      phasesContainer.innerHTML += phaseHtml;
    });

    // Add event listeners for checkboxes
    document.querySelectorAll('.algorithm-checkbox').forEach(checkbox => {
      checkbox.addEventListener('change', (e) => {
        const algoId = e.target.dataset.algoId;
        toggleCompletion(algoId);
        updateOverallProgress();
      });
    });

    updateOverallProgress();

  } catch (error) {
    console.error('Error loading learning path:', error);
  }
}

function isCompleted(algoId) {
  const completed = JSON.parse(localStorage.getItem('completed_algos') || '[]');
  return completed.includes(algoId);
}

function toggleCompletion(algoId) {
  let completed = JSON.parse(localStorage.getItem('completed_algos') || '[]');

  if (completed.includes(algoId)) {
    completed = completed.filter(id => id !== algoId);
  } else {
    completed.push(algoId);
  }

  localStorage.setItem('completed_algos', JSON.stringify(completed));
}

function updateOverallProgress() {
  const checkboxes = document.querySelectorAll('.algorithm-checkbox');
  const completed = Array.from(checkboxes).filter(cb => cb.checked).length;
  const total = checkboxes.length;
  const percentage = Math.round((completed / total) * 100);

  const progressBar = document.getElementById('overall-progress');
  progressBar.style.width = percentage + '%';
  progressBar.setAttribute('aria-valuenow', percentage);

  document.getElementById('progress-text').textContent = `${completed} / ${total}`;
}

document.addEventListener('DOMContentLoaded', loadLearningPath);
</script>
```

---

## Notes for Implementation

1. **API Endpoints**: Adjust the fetch URLs to match your actual Violet Rails API configuration
   - Typical format: `/api/v1/algorithms` or `/api_namespaces/algorithms/api_resources`

2. **Dynamic Routing**: You may need to configure custom routes in Violet Rails to handle `/algorithms/:id` URLs

3. **Authentication**: If the subdomain requires authentication, add appropriate checks

4. **Styling**: These templates use Bootstrap 4 classes. Adjust if your Violet Rails instance uses a different CSS framework

5. **Local Storage**: The learning path tracker uses browser localStorage to track completion. For production, consider saving to the database via API

6. **Rich Text**: The walkthrough content expects HTML. Ensure the API returns properly formatted HTML or use a markdown renderer

## Installation Steps

1. Log in to http://dsa.localhost:5250/admin
2. Navigate to **CMS** → **Pages**
3. Click **New Page**
4. Copy the content from each template above
5. Set the appropriate slug and layout
6. Publish the page
7. Test the functionality
