# Template Ecosystem Contributing Guide

> Build AI agents that deploy Rails apps from natural language.

This guide helps hackathon participants understand, extend, and contribute to the Template Ecosystem feature in the Violet App Agent.

## Quick Links

| Resource | Description |
|----------|-------------|
| [Demo Landing Page](../apps/agent/demo/index.html) | Try the agent live |
| [RFC-002](./RFC-002-template-ecosystem.md) | Design philosophy and architecture |
| [Template Designer](../apps/agent/src/violet_app_agent/subagents/template_designer.py) | Core implementation |
| [90s Nostalgia CSS](../apps/agent/src/violet_app_agent/templates/styles/90s_nostalgia.css) | Design system |

---

## What is the Template Ecosystem?

The Template Ecosystem solves a critical problem: **AI agents hallucinate non-existent code**.

When we asked LLMs to generate Liquid templates for Violet Rails, they invented tags like `render_api_form` that don't exist, causing runtime errors.

**Our solution:** A deterministic template system with:
1. **Verified Liquid Tags** - Whitelist of tags that actually exist
2. **90s Nostalgia CSS** - Automatic styling baked into every page
3. **Page Verification** - HTTP checks confirm pages render without errors

### The Workflow

```
1. generate_styled_page(page_type, slot_values, nav_links)
   → Returns styled HTML with 90s nostalgia CSS

2. create_page(subdomain, title, slug, content=styled_html)
   → Creates the page in CMS

3. verify_page(subdomain, slug)
   → Confirms the page renders without errors
```

---

## Architecture Overview

```
violet-app-agent/
├── apps/agent/
│   ├── src/violet_app_agent/
│   │   ├── agent.py                    # Main agent
│   │   ├── prompts.py                  # System prompts
│   │   ├── subagents/
│   │   │   ├── __init__.py            # Exports subagents
│   │   │   └── template_designer.py   # Template Designer (this feature!)
│   │   └── templates/
│   │       └── styles/
│   │           └── 90s_nostalgia.css  # Design system
│   └── demo/
│       ├── index.html                 # Landing page
│       └── chat_ui_streaming.html     # Chat interface
└── docs/
    ├── RFC-002-template-ecosystem.md  # Design doc
    └── TEMPLATE_ECOSYSTEM_CONTRIBUTING.md  # This file
```

### Deep Agent Pattern

The agent follows the **DIAGNOSE → MULTI-EXPERT → ARTIFACT-FIRST → DOMAIN-NATIVE** pattern:

```python
Main Agent (Orchestrator)
    ├── Architect Subagent (Data model design)
    ├── Template Designer Subagent ← THIS FEATURE
    ├── CMS Designer Subagent (Content management)
    ├── Content Researcher Subagent (Content generation)
    ├── Deployer Subagent (GitHub deployment)
    └── Security Subagent (Security checks)
```

---

## Setup for Development

### Prerequisites

- Python 3.11+
- Poetry
- Rails server running on port 5250
- PostgreSQL database

### Quick Start

```bash
# Clone and setup
cd violet_rails/violet-app-agent/apps/agent

# Install dependencies
poetry install

# Copy environment file
cp .env.example .env
# Edit .env with your ANTHROPIC_API_KEY

# Start the agent
poetry run langgraph dev --port 8123

# In another terminal, start Rails
cd violet_rails
bin/rails server -p 5250
```

### Verify Setup

```bash
# Check agent is running
curl http://localhost:8123/health

# Check Rails is running
curl http://localhost:5250
```

---

## Key Code Locations

### 1. Template Designer Subagent

**File:** `apps/agent/src/violet_app_agent/subagents/template_designer.py`

```python
# Verified Liquid tags that exist in Violet Rails
VERIFIED_LIQUID_TAGS = {
    "text": "{{ cms:text {identifier} }}",
    "markdown": "{{ cms:markdown {identifier} }}",
    "wysiwyg": "{{ cms:wysiwyg {identifier} }}",
    "asset": "{{ cms:asset {identifier}, as: image }}",
    "file": "{{ cms:file {identifier} }}",
    "snippet": "{{ cms:snippet {identifier} }}",
    "collection": "{{ cms:collection {identifier} | namespace: '{namespace}' }}",
    "form": "{{ render_form | namespace: '{namespace}' | submit_text: '{submit_text}' }}",
}

# Tags that DO NOT exist - agent must never use these
FORBIDDEN_TAGS = {
    "render_api_form": "Does not exist - use render_form instead",
    "api_resource": "Does not exist",
    "render_api": "Does not exist",
}
```

### 2. Template Library

```python
BLOG_TEMPLATES = {
    "home": {
        "name": "Blog Home Page",
        "slots": {
            "site_title": "Site title displayed in browser tab",
            "headline": "Main headline (h1)",
            "tagline": "Subtitle under headline",
            "footer_text": "Footer copyright/attribution",
        },
        "description": "Homepage with hero section and featured posts",
    },
    "category": { ... },
    "post_index": { ... },
    "post_show": { ... },
    "write": { ... },  # Has form_namespace for render_form
    "about": { ... },
}
```

### 3. Five Core Tools

| Tool | Purpose |
|------|---------|
| `list_templates()` | Show available page templates |
| `select_template(page_type)` | Get template definition with slots |
| `get_liquid_tag(tag_type, identifier)` | Return verified Liquid syntax |
| `generate_styled_page(page_type, slot_values)` | Create HTML with CSS |
| `verify_page(subdomain, path)` | HTTP check for render errors |

---

## Extension Ideas for Hackathon

### Beginner (2-4 hours)

1. **New Page Template** - Add a "contact" or "faq" template
2. **CSS Theme Variant** - Create a brutalist or minimalist theme
3. **New Liquid Tag** - Add a verified tag from Violet Rails

### Intermediate (4-8 hours)

4. **E-commerce Templates** - Product catalog, pricing pages
5. **SEO Optimizer Subagent** - Meta tags, OG tags, heading analysis
6. **Accessibility Checker** - WCAG compliance verification

### Advanced (8+ hours)

7. **Multi-page Generator** - Generate entire sites from descriptions
8. **Template Composition** - Header + body + footer system
9. **A/B Testing Support** - Template variations with analytics

---

## How to Add a New Template

### Step 1: Define the Template

```python
# In template_designer.py, add to BLOG_TEMPLATES:

"contact": {
    "name": "Contact Page",
    "file": "blog/contact.liquid",
    "slots": {
        "page_title": "Page title",
        "intro_text": "Introduction text",
        "email": "Contact email address",
        "phone": "Phone number (optional)",
    },
    "form_namespace": "contact",  # If it has a form
    "form_submit_text": "Send Message",
    "description": "Contact page with form and info",
},
```

### Step 2: Add Generation Logic

```python
# In generate_styled_page(), add a new elif block:

elif page_type == "contact":
    form_namespace = template.get("form_namespace", "contact")
    form_submit = template.get("form_submit_text", "Send")

    content_section = f"""
      <section>
        <h1>{slot_values.get("page_title", "Contact Us")}</h1>
        <p>{slot_values.get("intro_text", "")}</p>

        <div class="contact-info">
          <p>Email: {slot_values.get("email", "")}</p>
          <p>Phone: {slot_values.get("phone", "")}</p>
        </div>

        {{{{ render_form | namespace: '{form_namespace}' | submit_text: '{form_submit}' }}}}
      </section>
"""
```

### Step 3: Test It

```python
# Test in Python REPL
from violet_app_agent.subagents.template_designer import generate_styled_page

result = generate_styled_page(
    page_type="contact",
    slot_values={
        "page_title": "Get In Touch",
        "intro_text": "We'd love to hear from you!",
        "email": "hello@example.com",
    }
)

print(result["html"][:500])  # Preview first 500 chars
```

---

## How to Add a New CSS Theme

### Step 1: Create the CSS File

```css
/* In templates/styles/brutalist.css */

:root {
  --bg-cream: #ffffff;
  --bg-paper: #ffffff;
  --text-ink: #000000;
  --text-muted: #333333;
  --accent-teal: #000000;
  --accent-coral: #ff0000;
  --border-soft: #000000;

  --font-serif: "Courier New", monospace;
  --font-mono: "Courier New", monospace;
}

/* Override specific components */
.card {
  border: 3px solid black;
  box-shadow: 5px 5px 0 black;
}

a {
  text-decoration: none;
  border-bottom: 2px solid black;
}
```

### Step 2: Add Theme Selection

```python
# In template_designer.py

CSS_THEMES = {
    "90s_nostalgia": "90s_nostalgia.css",
    "brutalist": "brutalist.css",
    "minimalist": "minimalist.css",
}

def load_css(theme: str = "90s_nostalgia") -> str:
    css_file = CSS_THEMES.get(theme, "90s_nostalgia.css")
    css_path = TEMPLATES_DIR / "styles" / css_file
    return css_path.read_text() if css_path.exists() else ""
```

### Step 3: Update generate_styled_page

```python
def generate_styled_page(
    page_type: str,
    slot_values: dict[str, str],
    nav_links: list[dict[str, str]] | None = None,
    theme: str = "90s_nostalgia",  # Add theme parameter
) -> dict[str, Any]:
    css = load_css(theme)
    # ... rest of function
```

---

## How to Add a New Subagent

### Step 1: Create the Subagent File

```python
# In subagents/seo_optimizer.py

"""
SEO Optimizer Subagent

Analyzes and improves page SEO.
"""

from langchain_core.tools import tool
from deepagents import SubAgent

@tool
def analyze_seo(html: str) -> dict:
    """Analyze HTML for SEO issues."""
    issues = []

    if "<title>" not in html:
        issues.append("Missing <title> tag")
    if 'meta name="description"' not in html:
        issues.append("Missing meta description")
    if "<h1>" not in html:
        issues.append("Missing H1 tag")

    return {
        "score": 100 - (len(issues) * 20),
        "issues": issues,
        "recommendations": [f"Fix: {issue}" for issue in issues],
    }

@tool
def generate_meta_tags(title: str, description: str, keywords: list[str]) -> str:
    """Generate SEO meta tags."""
    return f'''
<title>{title}</title>
<meta name="description" content="{description}">
<meta name="keywords" content="{", ".join(keywords)}">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{description}">
'''

SEO_SUBAGENT_PROMPT = """You are the SEO Optimizer subagent.

Your role is to:
1. ANALYZE pages for SEO issues
2. GENERATE meta tags
3. RECOMMEND improvements

Always prioritize:
- Clear, descriptive titles
- Compelling meta descriptions
- Proper heading hierarchy
"""

seo_optimizer_subagent: SubAgent = {
    "name": "seo-optimizer-subagent",
    "description": "Analyzes and improves page SEO with meta tags and recommendations.",
    "system_prompt": SEO_SUBAGENT_PROMPT,
    "tools": [analyze_seo, generate_meta_tags],
}
```

### Step 2: Export from __init__.py

```python
# In subagents/__init__.py

from .seo_optimizer import (
    seo_optimizer_subagent,
    analyze_seo,
    generate_meta_tags,
)

__all__ = [
    # ... existing exports
    "seo_optimizer_subagent",
    "analyze_seo",
    "generate_meta_tags",
]
```

### Step 3: Register in Main Agent

```python
# In agent.py

from violet_app_agent.subagents import (
    # ... existing imports
    seo_optimizer_subagent,
    analyze_seo,
    generate_meta_tags,
)

def create_violet_app_agent():
    return create_deep_agent(
        tools=[
            # ... existing tools
            analyze_seo,
            generate_meta_tags,
        ],
        subagents=[
            # ... existing subagents
            seo_optimizer_subagent,
        ],
    )
```

---

## Testing Your Changes

### Unit Tests

```python
# In tests/test_template_designer.py

def test_contact_template():
    result = generate_styled_page(
        page_type="contact",
        slot_values={"page_title": "Contact"}
    )

    assert "error" not in result
    assert "Contact" in result["html"]
    assert "render_form" in result["html"]
    assert "render_api_form" not in result["html"]  # Forbidden!

def test_brutalist_theme():
    result = generate_styled_page(
        page_type="home",
        slot_values={"headline": "Test"},
        theme="brutalist"
    )

    assert "Courier New" in result["html"]
```

### Integration Tests

```python
def test_full_page_creation():
    # 1. Generate
    html_result = generate_styled_page(
        page_type="home",
        slot_values={"headline": "Test Site"}
    )

    # 2. Create (mock or use test subdomain)
    # create_page(subdomain="test", title="Home", content=html_result["html"])

    # 3. Verify
    # verify_result = verify_page(subdomain="test", path="/home")
    # assert verify_result["success"] is True
```

### Run Tests

```bash
cd violet-app-agent/apps/agent
poetry run pytest -v
poetry run pytest -v tests/test_template_designer.py
```

---

## Submission Checklist

Before submitting your hackathon project:

- [ ] Code runs without errors
- [ ] All new templates use only verified Liquid tags
- [ ] Pages verify successfully with `verify_page()`
- [ ] Tests pass
- [ ] README explains what you built
- [ ] Demo video (2-3 minutes) shows it working

---

## Common Pitfalls

### 1. Hallucinated Liquid Tags

**Wrong:**
```python
"{{ render_api_form | namespace: 'contact' }}"  # DOESN'T EXIST!
```

**Right:**
```python
"{{ render_form | namespace: 'contact' | submit_text: 'Send' }}"
```

### 2. Forgetting to Verify

Always call `verify_page()` after creating a page:

```python
# After create_page()
result = verify_page(subdomain="my-site", path="/contact")
if not result["success"]:
    print(f"Page has errors: {result}")
```

### 3. Missing Slots

Templates have required slots. Check them:

```python
template = select_template("home")
print(template["slots"])  # Shows required slot names
```

---

## Getting Help

- **GitHub Issues:** [restarone/violet_rails](https://github.com/restarone/violet_rails/issues)
- **Demo:** Open `demo/index.html` and click "Try It Live"
- **RFC:** Read `docs/RFC-002-template-ecosystem.md` for design rationale

---

## Design Philosophy

From RFC-002:

> **"Don't Make Me Think Revisited"** (Steve Krug)
> - Clear, obvious navigation
> - Every click should be obvious
> - Room to breathe
> - Users scan, not read

The 90s nostalgia aesthetic:
- Cream backgrounds (#f5f0e6)
- Georgia serif typography
- Teal (#2a9d8f) and coral (#e76f51) accents
- CSS Grid layout with generous whitespace
- Paper-white cards with subtle borders

---

## License

This project is part of Violet Rails, licensed under [MIT License](../../LICENSE).

---

**Built for the Violet Rails Hackathon - "Building with AI" Track**
