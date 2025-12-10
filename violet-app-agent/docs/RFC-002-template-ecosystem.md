# RFC-002: Template Ecosystem & Agent Actions Critique

**Status:** Draft
**Author:** Violet App Agent Team
**Created:** 2025-12-09
**Related PR:** #1719
**Depends On:** RFC-001 (Plan Mode UX)

## Executive Summary

This RFC critiques the agent's actions during the "Conscious Observer" blog build, defines success criteria for verification, and proposes a Template Ecosystem that ensures deterministic, working page generation with 90's low-tech nostalgia styling.

---

## Part 1: Composite Evaluation of Agent Journey

### What the Agent Built

| Page | URL | Status | Quality |
|------|-----|--------|---------|
| Landing | `/` | Default | Generic Violet Rails welcome |
| Home | `/home` | Working | Good structure, 3 content cards |
| Toronto | `/toronto` | Working | Rich narrative, blockquote |
| Jersey City | `/jersey-city` | Working | Most personalized, references chaiwithjai.com |
| Stories | `/stories` | Empty | Blank page - no content |
| Write | `/write` | **BROKEN** | `NoMethodError: undefined method 'render_api_form'` |

### Screenshot Evidence

```
eval-01-landing-page.png    → Generic "Hello from conscious-observer"
eval-02-home-page.png       → 3 cards: Toronto, Jersey City, Observation
eval-03-stories-empty.png   → Completely blank white page
eval-04-toronto-page.png    → Rich content with cultural narrative
eval-05-jersey-city-page.png → Jai's story, chai references, November 2025
eval-06-write-error.png     → NoMethodError stack trace
```

### What Went Right

1. **Subdomain Creation**: `conscious-observer` created successfully
2. **Content Generation**: Agent generated compelling, personalized content:
   - Toronto: "cultural crossroads", "international origins"
   - Jersey City: "November 2025", "Heights", references to chaiwithjai.com
3. **Information Architecture**: Logical page hierarchy with clear navigation
4. **Personal Voice**: Content matches the "Jai Bhagat" persona well

### What Went Wrong

1. **Non-Existent Liquid Tag**: Agent used `render_api_form` which doesn't exist in Violet Rails
   - Should have used `render_form` or built a static HTML form
   - This is a **domain knowledge gap** - agent doesn't know available Liquid tags

2. **Empty Stories Page**: `/stories` was created but has no content
   - Either the page content failed to save, or agent didn't populate it

3. **No Verification**: Agent didn't verify pages actually render before reporting success
   - A simple GET request to each page would have caught the `/write` error

4. **No Styling**: Pages are unstyled browser defaults
   - No CSS was applied
   - Functional but not visually appealing

---

## Part 2: Success Criteria for Verification

### Definition of "Done" for Page Creation

A page is only successfully created when ALL criteria pass:

```python
class PageVerificationCriteria:
    """Success criteria for page creation verification."""

    MUST_PASS = {
        "page_exists": "Page record exists in database",
        "page_renders": "GET request returns 200 (not 500)",
        "no_errors": "No NoMethodError, NameError, or SyntaxError",
        "content_present": "Page has visible content (not blank)",
        "links_work": "Internal links resolve to existing pages",
    }

    SHOULD_PASS = {
        "styling_applied": "CSS styles are present",
        "semantic_html": "Uses proper heading hierarchy",
        "mobile_friendly": "Viewport meta tag present",
    }

    NICE_TO_HAVE = {
        "accessibility": "Alt text on images, proper ARIA",
        "performance": "Page loads in < 3 seconds",
    }
```

### Verification Tool Implementation

```python
@tool
def verify_page(subdomain: str, path: str) -> dict:
    """
    Verify a page was created successfully and renders without errors.

    Args:
        subdomain: The subdomain name (e.g., 'conscious-observer')
        path: The page path (e.g., '/home')

    Returns:
        dict with verification results
    """
    url = f"http://{subdomain}.localhost:5250{path}"

    try:
        response = requests.get(url, timeout=10)

        return {
            "success": response.status_code == 200,
            "status_code": response.status_code,
            "has_content": len(response.text) > 100,
            "has_error": "NoMethodError" in response.text or "Error" in response.text,
            "content_length": len(response.text),
            "url": url,
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "url": url,
        }
```

### E2E Verification Test Suite

```python
class TestBlogDelivery:
    """E2E tests verifying the delivered blog artifact."""

    @pytest.fixture
    def subdomain(self):
        return "conscious-observer"

    def test_home_page_renders(self, subdomain):
        """Home page should render with content cards."""
        result = verify_page(subdomain, "/home")
        assert result["success"], f"Home page failed: {result}"
        assert result["has_content"], "Home page is empty"
        assert not result["has_error"], "Home page has errors"

    def test_all_linked_pages_work(self, subdomain):
        """All links from home should resolve."""
        links = ["/stories", "/write", "/toronto", "/jersey-city"]
        failures = []

        for link in links:
            result = verify_page(subdomain, link)
            if not result["success"] or result["has_error"]:
                failures.append(f"{link}: {result}")

        assert not failures, f"Broken links: {failures}"

    def test_no_500_errors(self, subdomain):
        """No page should return a 500 error."""
        pages = ["/", "/home", "/stories", "/write", "/toronto", "/jersey-city"]

        for page in pages:
            result = verify_page(subdomain, page)
            assert result.get("status_code") != 500, f"{page} returns 500"
```

---

## Part 3: Real-World Expectations

### What Users Expect vs What They Get

| Expectation | Current Reality | Gap |
|-------------|-----------------|-----|
| "A working blog" | 4/6 pages work | `/stories` empty, `/write` broken |
| "Professional styling" | Browser defaults | No CSS applied |
| "Ready to add content" | Missing forms | Can't submit stories |
| "Mobile friendly" | Unstyled = responsive-ish | No viewport meta |

### User Journey Pain Points

1. **First Impression**: Landing at `/` shows generic welcome, not custom blog
2. **Broken Flow**: Clicking "Share Your Story" leads to error page
3. **Empty Sections**: Stories page is blank - looks like something broke
4. **No Visual Identity**: Plain HTML doesn't convey blog personality

### Real-World Success Definition

```yaml
definition_of_done:
  functional:
    - All 6 pages render without errors
    - Navigation links all work
    - Story submission form functional
    - Content displays correctly

  visual:
    - Consistent styling across pages
    - Typography reflects blog personality
    - Color scheme applied
    - Mobile responsive

  content:
    - Home has introductory content
    - Category pages have descriptions
    - At least one sample post
    - Clear calls-to-action
```

---

## Part 4: Deterministic Tool Calls

### The Problem

Agent generated Liquid code using non-existent helpers:

```liquid
<!-- Agent generated this (BROKEN) -->
{{ render_api_form | namespace: "story" | submit_text: "Share Your Story" }}

<!-- Should have been one of these (WORKING) -->
{{ cms:snippet story_form }}
<form action="/api/stories" method="POST">...</form>
```

### Root Cause

The agent:
1. Knows Violet Rails has forms
2. Doesn't know the exact Liquid tag syntax
3. "Hallucinated" a plausible-sounding tag name
4. Didn't verify the tag exists before using it

### Solution: Deterministic Template Library

Instead of generating Liquid code, agent selects from verified templates:

```python
VERIFIED_LIQUID_TAGS = {
    # Content tags (SAFE - always work)
    "text": "{{ cms:text identifier }}",
    "markdown": "{{ cms:markdown identifier }}",
    "wysiwyg": "{{ cms:wysiwyg identifier }}",

    # Asset tags (SAFE)
    "asset": "{{ cms:asset identifier, as: image }}",
    "file": "{{ cms:file identifier }}",

    # Snippet tags (SAFE - if snippet exists)
    "snippet": "{{ cms:snippet identifier }}",

    # Collection tags (SAFE)
    "collection": "{{ cms:collection identifier | namespace: 'name' }}",

    # Form tags (USE render_form NOT render_api_form)
    "form": "{{ render_form | namespace: 'name' }}",
}

FORBIDDEN_TAGS = {
    "render_api_form": "Does not exist - use render_form",
    "api_resource": "Does not exist",
}
```

### Validation Before Execution

```python
def validate_liquid_content(content: str) -> tuple[bool, list[str]]:
    """
    Validate Liquid content only uses known tags.

    Returns:
        (is_valid, list of errors)
    """
    errors = []

    for forbidden, reason in FORBIDDEN_TAGS.items():
        if forbidden in content:
            errors.append(f"Forbidden tag '{forbidden}': {reason}")

    return len(errors) == 0, errors
```

---

## Part 5: Template Ecosystem for Blog Use Case

### Design Philosophy: "Don't Make Me Think Revisited"

Following Steve Krug's principles:

1. **Don't make users think** - Clear, obvious navigation
2. **Every click should be obvious** - No mystery meat navigation
3. **Get rid of half the words, then get rid of half of what's left**
4. **Satisfice** - Users don't read, they scan

### Template Structure

```
templates/
├── blog/
│   ├── base.liquid           # Base layout with CSS Grid
│   ├── home.liquid           # Featured posts + categories
│   ├── post_index.liquid     # All posts with filters
│   ├── post_show.liquid      # Single post view
│   ├── category.liquid       # Posts by category
│   ├── author.liquid         # Author profile + posts
│   └── write.liquid          # Story submission form
├── components/
│   ├── header.liquid         # Navigation
│   ├── footer.liquid         # Footer with links
│   ├── post_card.liquid      # Post preview card
│   └── category_pill.liquid  # Category badge
└── styles/
    └── 90s-nostalgia.css     # The aesthetic
```

### 90's Low-Tech Nostalgia CSS

```css
/* 90s-nostalgia.css - Design that breathes */

:root {
  /* Colors: Muted, warm, nostalgic */
  --bg-cream: #f5f0e6;
  --bg-paper: #fffef9;
  --text-ink: #2c2c2c;
  --text-muted: #5a5a5a;
  --accent-teal: #2a9d8f;
  --accent-coral: #e76f51;
  --border-soft: #d4cfc4;

  /* Typography: Georgia for that web 1.0 feel */
  --font-serif: Georgia, "Times New Roman", serif;
  --font-mono: "Courier New", Courier, monospace;

  /* Sizes: Generous, readable */
  --text-sm: 0.875rem;
  --text-base: 1.125rem;
  --text-lg: 1.5rem;
  --text-xl: 2rem;
  --text-2xl: 2.5rem;

  /* Spacing: Room to breathe */
  --space-xs: 0.5rem;
  --space-sm: 1rem;
  --space-md: 2rem;
  --space-lg: 4rem;
  --space-xl: 8rem;
}

/* Base: Paper-like background */
body {
  font-family: var(--font-serif);
  font-size: var(--text-base);
  line-height: 1.7;
  color: var(--text-ink);
  background: var(--bg-cream);
  margin: 0;
  padding: 0;
}

/* CSS Grid Layout: Simple 12-column */
.container {
  display: grid;
  grid-template-columns:
    [full-start] minmax(var(--space-md), 1fr)
    [content-start] minmax(0, 720px)
    [content-end] minmax(var(--space-md), 1fr)
    [full-end];
  row-gap: var(--space-lg);
}

.container > * {
  grid-column: content;
}

/* Full-bleed elements */
.full-bleed {
  grid-column: full;
}

/* Typography: Semantic, scannable */
h1, h2, h3 {
  font-family: var(--font-serif);
  font-weight: normal;
  letter-spacing: -0.02em;
  margin: 0 0 var(--space-sm);
}

h1 {
  font-size: var(--text-2xl);
  line-height: 1.2;
}

h2 {
  font-size: var(--text-xl);
  color: var(--text-muted);
}

h3 {
  font-size: var(--text-lg);
}

p {
  margin: 0 0 var(--space-sm);
}

/* Links: Underlined, obvious */
a {
  color: var(--accent-teal);
  text-decoration: underline;
  text-underline-offset: 3px;
}

a:hover {
  color: var(--accent-coral);
}

/* Cards: Subtle elevation */
.card {
  background: var(--bg-paper);
  border: 1px solid var(--border-soft);
  padding: var(--space-md);
  margin-bottom: var(--space-md);
}

/* Blockquotes: Pull quotes */
blockquote {
  font-style: italic;
  border-left: 3px solid var(--accent-teal);
  padding-left: var(--space-md);
  margin: var(--space-md) 0;
  color: var(--text-muted);
}

/* Navigation: Simple, horizontal */
nav {
  display: flex;
  gap: var(--space-md);
  padding: var(--space-md) 0;
  border-bottom: 1px solid var(--border-soft);
}

nav a {
  text-decoration: none;
  color: var(--text-ink);
}

nav a:hover {
  text-decoration: underline;
}

/* Forms: Clean, accessible */
.form-group {
  margin-bottom: var(--space-md);
}

label {
  display: block;
  margin-bottom: var(--space-xs);
  font-weight: bold;
}

input, textarea {
  width: 100%;
  padding: var(--space-sm);
  font-family: var(--font-serif);
  font-size: var(--text-base);
  border: 1px solid var(--border-soft);
  background: var(--bg-paper);
}

textarea {
  min-height: 200px;
  resize: vertical;
}

button {
  font-family: var(--font-serif);
  font-size: var(--text-base);
  padding: var(--space-sm) var(--space-md);
  background: var(--accent-teal);
  color: white;
  border: none;
  cursor: pointer;
}

button:hover {
  background: var(--accent-coral);
}

/* Post cards grid */
.posts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: var(--space-md);
}

/* Category pills */
.category-pill {
  display: inline-block;
  font-size: var(--text-sm);
  padding: var(--space-xs) var(--space-sm);
  background: var(--bg-cream);
  border: 1px solid var(--border-soft);
  color: var(--text-muted);
  text-decoration: none;
}

/* Footer */
footer {
  margin-top: var(--space-xl);
  padding: var(--space-md) 0;
  border-top: 1px solid var(--border-soft);
  font-size: var(--text-sm);
  color: var(--text-muted);
}

/* Responsive: Mobile-first */
@media (max-width: 600px) {
  :root {
    --text-base: 1rem;
    --text-xl: 1.5rem;
    --text-2xl: 2rem;
    --space-md: 1.5rem;
    --space-lg: 2rem;
  }

  nav {
    flex-direction: column;
    gap: var(--space-sm);
  }
}
```

### Template: Home Page

```liquid
<!-- templates/blog/home.liquid -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{ cms:text site_title }}</title>
  <style>
    /* Inline 90s-nostalgia.css here */
  </style>
</head>
<body>
  <div class="container">
    <header>
      <nav>
        <a href="/">Home</a>
        <a href="/stories">Stories</a>
        <a href="/write">Write</a>
      </nav>
    </header>

    <main>
      <section class="hero">
        <h1>{{ cms:text headline }}</h1>
        <p>{{ cms:text tagline }}</p>
      </section>

      <section class="categories">
        <h2>Explore</h2>
        <div class="posts-grid">
          {{ cms:snippet category_cards }}
        </div>
      </section>

      <section class="featured">
        <h2>Featured Stories</h2>
        {{ cms:collection featured_posts | namespace: 'posts' }}
      </section>
    </main>

    <footer>
      <p>{{ cms:text footer_text }}</p>
    </footer>
  </div>
</body>
</html>
```

### Template: Write/Submit Page (FIXED)

```liquid
<!-- templates/blog/write.liquid -->
<!-- NOTE: Uses render_form NOT render_api_form -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Share Your Story | {{ cms:text site_title }}</title>
  <style>/* 90s-nostalgia.css */</style>
</head>
<body>
  <div class="container">
    <header>
      <nav>
        <a href="/">Home</a>
        <a href="/stories">Stories</a>
        <a href="/write">Write</a>
      </nav>
    </header>

    <main>
      <h1>Share Your Story</h1>
      <p>{{ cms:text write_intro }}</p>

      <!-- CORRECT: Using render_form -->
      {{ render_form | namespace: 'stories' | submit_text: 'Share Your Story' }}
    </main>

    <footer>
      <p>{{ cms:text footer_text }}</p>
    </footer>
  </div>
</body>
</html>
```

---

## Part 6: Template Subagent Architecture

### Deep Agent Integration

Following the DIAGNOSE → MULTI-EXPERT → ARTIFACT-FIRST → DOMAIN-NATIVE pattern:

```
                         ┌─────────────────────┐
                         │   Main Agent        │
                         │   (Orchestrator)    │
                         └─────────┬───────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
           ▼                       ▼                       ▼
    ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
    │  Architect   │       │  Template    │       │  Deployer    │
    │  Subagent    │       │  Subagent    │◄──NEW │  Subagent    │
    └──────────────┘       └──────────────┘       └──────────────┘
           │                       │                       │
           │                       │                       │
    ┌──────┴──────┐         ┌──────┴──────┐         ┌──────┴──────┐
    │ Data Model  │         │ Template    │         │ GitHub      │
    │ Design      │         │ Selection   │         │ Deployment  │
    └─────────────┘         │ + Styling   │         └─────────────┘
                            │ + Verify    │
                            └─────────────┘
```

### Template Subagent Definition

```python
# src/violet_app_agent/subagents/template_designer.py

from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent
from langchain_anthropic import ChatAnthropic

TEMPLATE_SUBAGENT_PROMPT = """You are the Template Designer subagent for the Violet App Agent.

Your role is to:
1. SELECT appropriate templates from the verified template library
2. CUSTOMIZE templates with user-specific content
3. APPLY styling (90s nostalgia CSS by default)
4. VERIFY each page renders successfully after creation

CRITICAL RULES:
- ONLY use Liquid tags from VERIFIED_LIQUID_TAGS
- NEVER use render_api_form (it doesn't exist) - use render_form
- ALWAYS verify pages after creation
- Report any rendering errors immediately

Available Templates:
- blog/home.liquid - Homepage with hero, categories, featured posts
- blog/post_index.liquid - All posts listing
- blog/post_show.liquid - Single post view
- blog/category.liquid - Posts filtered by category
- blog/write.liquid - Story submission form (uses render_form)

Default Style: 90s-nostalgia.css
- Cream background, paper-white cards
- Georgia serif typography
- Teal/coral accents
- CSS Grid layout
- Generous whitespace
"""

@tool
def select_template(page_type: str) -> dict:
    """
    Select the appropriate template for a page type.

    Args:
        page_type: One of 'home', 'post_index', 'post_show', 'category', 'write'

    Returns:
        Template definition with content slots
    """
    templates = {
        "home": {
            "file": "blog/home.liquid",
            "slots": ["headline", "tagline", "category_cards", "featured_posts"],
            "style": "90s-nostalgia.css",
        },
        "write": {
            "file": "blog/write.liquid",
            "slots": ["write_intro"],
            "form": "render_form",  # NOT render_api_form!
            "style": "90s-nostalgia.css",
        },
        # ... other templates
    }
    return templates.get(page_type, {})


@tool
def apply_template(
    subdomain: str,
    path: str,
    template_name: str,
    content: dict
) -> dict:
    """
    Apply a template to create a page with styling.

    Args:
        subdomain: Target subdomain
        path: Page path (e.g., '/home')
        template_name: Template to use (e.g., 'blog/home.liquid')
        content: Dict of slot names to content values

    Returns:
        Result with page URL and verification status
    """
    # Load template
    # Fill slots
    # Apply CSS
    # Create page via rails_runner
    # VERIFY the page renders
    verification = verify_page(subdomain, path)

    return {
        "page_url": f"http://{subdomain}.localhost:5250{path}",
        "template": template_name,
        "verified": verification["success"],
        "errors": verification.get("errors", []),
    }


@tool
def verify_page(subdomain: str, path: str) -> dict:
    """Verify a page renders without errors."""
    # Implementation from Part 2
    pass


def create_template_subagent():
    """Create the Template Designer subagent."""
    model = ChatAnthropic(model="claude-sonnet-4-20250514", temperature=0)

    tools = [
        select_template,
        apply_template,
        verify_page,
    ]

    return create_react_agent(
        model,
        tools,
        state_modifier=TEMPLATE_SUBAGENT_PROMPT,
    )
```

### Integration with Main Agent

```python
# In agent.py - Updated tool list

def create_agent():
    """Create the main Violet App Agent with template subagent."""

    # Subagents
    architect = create_architect_subagent()
    template_designer = create_template_subagent()  # NEW
    deployer = create_deployer_subagent()

    tools = [
        # Infrastructure
        create_subdomain,
        create_namespace,

        # Templates (NEW - deterministic)
        select_template,
        apply_template,
        verify_page,

        # Deployment
        trigger_deployment,
    ]

    return create_react_agent(model, tools, state_modifier=SYSTEM_PROMPT)
```

---

## Part 7: Implementation Roadmap

### Phase 1: Fix Critical Issues (Immediate)

1. [ ] Fix `/write` page - replace `render_api_form` with `render_form`
2. [ ] Add content to `/stories` page
3. [ ] Implement `verify_page` tool
4. [ ] Add verification step after each `create_page` call

### Phase 2: Template Ecosystem (Week 1)

1. [ ] Create verified template library (6 templates)
2. [ ] Implement `select_template` tool
3. [ ] Implement `apply_template` tool with CSS injection
4. [ ] Write 90s-nostalgia.css

### Phase 3: Template Subagent (Week 2)

1. [ ] Create Template Designer subagent
2. [ ] Integrate with main agent graph
3. [ ] Add template selection to Plan Phase
4. [ ] E2E tests for template application

### Phase 4: Verification Suite (Week 3)

1. [ ] Full verification test suite
2. [ ] Automated screenshot comparison
3. [ ] Mobile responsiveness checks
4. [ ] Performance baseline tests

---

## Appendix: Verified Liquid Tags Reference

```yaml
# SAFE TO USE - These tags exist and work
content_tags:
  - "{{ cms:text identifier }}"
  - "{{ cms:markdown identifier }}"
  - "{{ cms:wysiwyg identifier }}"

asset_tags:
  - "{{ cms:asset identifier, as: image }}"
  - "{{ cms:file identifier }}"

snippet_tags:
  - "{{ cms:snippet identifier }}"

collection_tags:
  - "{{ cms:collection identifier | namespace: 'name' }}"

form_tags:
  - "{{ render_form | namespace: 'name' }}"  # CORRECT

# FORBIDDEN - These DO NOT exist
forbidden:
  - render_api_form  # Use render_form instead
  - api_resource     # Does not exist
  - render_api       # Does not exist
```

---

## Conclusion

The Conscious Observer blog build revealed critical gaps in the agent's domain knowledge and verification processes. By implementing:

1. **Deterministic templates** with verified Liquid tags
2. **Mandatory verification** after page creation
3. **A Template Subagent** following Deep Agent architecture
4. **90s nostalgia styling** for visual identity

We can ensure that future builds produce working, styled, verified artifacts that match user expectations from Day 0.

The template ecosystem transforms the agent from a "generate and hope" model to a "select, apply, and verify" model - dramatically improving reliability while maintaining flexibility for customization.
