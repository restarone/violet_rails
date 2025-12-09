"""
Template Designer Subagent

Following Deep Agent architecture: DIAGNOSE -> MULTI-EXPERT -> ARTIFACT-FIRST -> DOMAIN-NATIVE

This subagent is responsible for:
1. SELECT appropriate templates from the verified template library
2. CUSTOMIZE templates with user-specific content
3. APPLY styling (90s nostalgia CSS by default)
4. VERIFY each page renders successfully after creation

CRITICAL: Only uses verified Liquid tags that exist in Violet Rails.
"""

import os
import requests
from pathlib import Path
from typing import Any

from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent
from langchain_anthropic import ChatAnthropic


# Template directory path
TEMPLATES_DIR = Path(__file__).parent.parent / "templates"


# Verified Liquid tags that exist in Violet Rails
VERIFIED_LIQUID_TAGS = {
    # Content tags (SAFE - always work)
    "text": "{{ cms:text {identifier} }}",
    "markdown": "{{ cms:markdown {identifier} }}",
    "wysiwyg": "{{ cms:wysiwyg {identifier} }}",

    # Asset tags (SAFE)
    "asset": "{{ cms:asset {identifier}, as: image }}",
    "file": "{{ cms:file {identifier} }}",

    # Snippet tags (SAFE - if snippet exists)
    "snippet": "{{ cms:snippet {identifier} }}",

    # Collection tags (SAFE)
    "collection": "{{ cms:collection {identifier} | namespace: '{namespace}' }}",

    # Form tags (USE render_form NOT render_api_form)
    "form": "{{ render_form | namespace: '{namespace}' | submit_text: '{submit_text}' }}",
}

# Tags that DO NOT exist - agent must never use these
FORBIDDEN_TAGS = {
    "render_api_form": "Does not exist - use render_form instead",
    "api_resource": "Does not exist",
    "render_api": "Does not exist",
}


# Blog templates library
BLOG_TEMPLATES = {
    "home": {
        "name": "Blog Home Page",
        "file": "blog/home.liquid",
        "slots": {
            "site_title": "Site title displayed in browser tab",
            "headline": "Main headline (h1)",
            "tagline": "Subtitle under headline",
            "footer_text": "Footer copyright/attribution",
        },
        "description": "Homepage with hero section, category cards, and featured posts",
    },
    "category": {
        "name": "Category Page",
        "file": "blog/category.liquid",
        "slots": {
            "category_title": "Category name (h1)",
            "category_description": "Category description",
            "category_content": "Main content area",
        },
        "description": "Category landing page with description and posts",
    },
    "post_index": {
        "name": "Posts Index",
        "file": "blog/post_index.liquid",
        "slots": {
            "page_title": "Page title",
            "intro_text": "Introduction paragraph",
        },
        "description": "List all posts with filtering options",
    },
    "post_show": {
        "name": "Single Post",
        "file": "blog/post_show.liquid",
        "slots": {
            "post_title": "Post title",
            "post_content": "Full post content",
            "post_author": "Author name",
            "post_date": "Publication date",
        },
        "description": "Individual post view with full content",
    },
    "write": {
        "name": "Submit Story Form",
        "file": "blog/write.liquid",
        "slots": {
            "page_title": "Page title",
            "intro_text": "Introduction/instructions",
        },
        "form_namespace": "stories",
        "form_submit_text": "Share Your Story",
        "description": "Story submission form - uses render_form (NOT render_api_form)",
    },
    "about": {
        "name": "About Page",
        "file": "blog/about.liquid",
        "slots": {
            "page_title": "Page title",
            "about_content": "About section content",
        },
        "description": "About page with author/site information",
    },
}


TEMPLATE_SUBAGENT_PROMPT = """You are the Template Designer subagent for the Violet App Agent.

Your role is to:
1. SELECT appropriate templates from the verified template library
2. CUSTOMIZE templates with user-specific content
3. APPLY styling (90s nostalgia CSS by default)
4. VERIFY each page renders successfully after creation

## CRITICAL RULES

1. **ONLY use Liquid tags from VERIFIED_LIQUID_TAGS**
   - text, markdown, wysiwyg: Content display
   - asset, file: Media
   - snippet: Reusable content blocks
   - collection: Data collections
   - form: User forms (render_form)

2. **NEVER use these tags (they don't exist):**
   - render_api_form (DOES NOT EXIST - use render_form)
   - api_resource (DOES NOT EXIST)
   - render_api (DOES NOT EXIST)

3. **ALWAYS verify pages after creation**
   - Use verify_page tool after every create_page
   - Report errors immediately
   - Do not mark complete until verified

4. **Use 90s nostalgia CSS by default**
   - Cream backgrounds, paper-white cards
   - Georgia serif typography
   - Teal/coral accents
   - CSS Grid layout
   - Generous whitespace

## Available Templates

- home: Homepage with hero, categories, featured posts
- category: Category landing page
- post_index: All posts listing
- post_show: Single post view
- write: Story submission form (uses render_form, NOT render_api_form)
- about: About page

## Example Workflow

1. User wants a home page -> select_template("home")
2. Fill slots with content
3. Apply 90s nostalgia CSS
4. Create page via apply_template
5. Verify page renders -> verify_page
6. Report success or errors
"""


def load_css() -> str:
    """Load the 90s nostalgia CSS file."""
    css_path = TEMPLATES_DIR / "styles" / "90s_nostalgia.css"
    if css_path.exists():
        return css_path.read_text()
    return ""


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


@tool
def list_templates() -> dict[str, Any]:
    """
    List all available blog templates with their descriptions.

    Returns:
        Dictionary of template names to their metadata
    """
    return {
        name: {
            "name": t["name"],
            "description": t["description"],
            "slots": list(t["slots"].keys()),
        }
        for name, t in BLOG_TEMPLATES.items()
    }


@tool
def select_template(page_type: str) -> dict[str, Any]:
    """
    Select the appropriate template for a page type.

    Args:
        page_type: One of 'home', 'category', 'post_index', 'post_show', 'write', 'about'

    Returns:
        Template definition with content slots and requirements
    """
    if page_type not in BLOG_TEMPLATES:
        return {
            "error": f"Unknown page type: {page_type}",
            "available": list(BLOG_TEMPLATES.keys()),
        }

    template = BLOG_TEMPLATES[page_type]
    result = {
        "page_type": page_type,
        "template_name": template["name"],
        "template_file": template["file"],
        "slots": template["slots"],
        "description": template["description"],
        "style": "90s_nostalgia.css",
    }

    # Add form info if applicable
    if "form_namespace" in template:
        result["form"] = {
            "namespace": template["form_namespace"],
            "submit_text": template["form_submit_text"],
            "liquid_tag": f"{{{{ render_form | namespace: '{template['form_namespace']}' | submit_text: '{template['form_submit_text']}' }}}}",
            "warning": "NEVER use render_api_form - it does not exist!",
        }

    return result


@tool
def get_liquid_tag(tag_type: str, identifier: str = "", namespace: str = "", submit_text: str = "Submit") -> dict[str, Any]:
    """
    Get the correct Liquid tag syntax for a given tag type.

    Args:
        tag_type: Type of tag (text, markdown, collection, form, etc.)
        identifier: Content identifier
        namespace: Namespace for collection/form tags
        submit_text: Button text for form tags

    Returns:
        The correct Liquid syntax to use
    """
    if tag_type not in VERIFIED_LIQUID_TAGS:
        return {
            "error": f"Unknown tag type: {tag_type}",
            "available": list(VERIFIED_LIQUID_TAGS.keys()),
        }

    template = VERIFIED_LIQUID_TAGS[tag_type]
    result = template.format(
        identifier=identifier,
        namespace=namespace,
        submit_text=submit_text,
    )

    return {
        "tag_type": tag_type,
        "syntax": result,
        "warning": "Never use render_api_form - it does not exist!" if tag_type == "form" else None,
    }


@tool
def verify_page(subdomain: str, path: str) -> dict[str, Any]:
    """
    Verify a page was created successfully and renders without errors.

    CRITICAL: Call this after EVERY page creation to ensure it works.

    Args:
        subdomain: The subdomain name (e.g., 'conscious-observer')
        path: The page path (e.g., '/home')

    Returns:
        Verification results including success status and any errors
    """
    # Construct URL - handle path with or without leading slash
    if not path.startswith("/"):
        path = f"/{path}"

    url = f"http://{subdomain}.localhost:5250{path}"

    try:
        response = requests.get(url, timeout=10)

        # Check for known error patterns
        has_error = any(err in response.text for err in [
            "NoMethodError",
            "NameError",
            "SyntaxError",
            "undefined method",
            "ActionView::Template::Error",
            "Action Controller: Exception",
        ])

        # Check for specific forbidden tag errors
        forbidden_tag_errors = []
        for tag in FORBIDDEN_TAGS:
            if tag in response.text:
                forbidden_tag_errors.append(f"Page uses forbidden tag: {tag}")

        return {
            "success": response.status_code == 200 and not has_error,
            "url": url,
            "status_code": response.status_code,
            "has_content": len(response.text) > 100,
            "has_error": has_error,
            "forbidden_tag_errors": forbidden_tag_errors,
            "content_length": len(response.text),
            "recommendation": "Page OK" if (response.status_code == 200 and not has_error) else "Fix errors before proceeding",
        }

    except requests.exceptions.ConnectionError:
        return {
            "success": False,
            "url": url,
            "error": "Connection refused - is the Rails server running?",
            "recommendation": "Start Rails server: bin/rails server -p 5250",
        }
    except requests.exceptions.Timeout:
        return {
            "success": False,
            "url": url,
            "error": "Request timed out",
            "recommendation": "Check server status and try again",
        }
    except Exception as e:
        return {
            "success": False,
            "url": url,
            "error": str(e),
            "recommendation": "Investigate the error",
        }


@tool
def generate_styled_page(
    page_type: str,
    slot_values: dict[str, str],
    nav_links: list[dict[str, str]] | None = None,
) -> dict[str, Any]:
    """
    Generate a complete styled page HTML with 90s nostalgia CSS.

    Args:
        page_type: Template type (home, category, write, etc.)
        slot_values: Dict mapping slot names to content values
        nav_links: Optional list of nav links [{"text": "Home", "href": "/"}]

    Returns:
        Complete HTML ready to be used as page content
    """
    if page_type not in BLOG_TEMPLATES:
        return {
            "error": f"Unknown page type: {page_type}",
            "available": list(BLOG_TEMPLATES.keys()),
        }

    template = BLOG_TEMPLATES[page_type]
    css = load_css()

    # Default navigation
    if nav_links is None:
        nav_links = [
            {"text": "Home", "href": "/home"},
            {"text": "Stories", "href": "/stories"},
            {"text": "Write", "href": "/write"},
        ]

    nav_html = "\n".join(
        f'        <a href="{link["href"]}">{link["text"]}</a>'
        for link in nav_links
    )

    # Get slot values with defaults
    site_title = slot_values.get("site_title", "My Blog")
    headline = slot_values.get("headline", "Welcome")
    tagline = slot_values.get("tagline", "")
    main_content = slot_values.get("main_content", "")
    footer_text = slot_values.get("footer_text", "Made with Violet Rails")

    # Generate page-type specific content
    if page_type == "home":
        content_section = f"""
      <section class="hero">
        <h1>{headline}</h1>
        <p>{tagline}</p>
        <div class="hero-cta">
          <a href="/stories">Read Stories</a>
          <a href="/write">Share Your Story</a>
        </div>
      </section>

      <section>
        <h2>Explore</h2>
        <div class="content-cards">
          {main_content}
        </div>
      </section>
"""
    elif page_type == "write":
        # CRITICAL: Use render_form, NOT render_api_form
        form_namespace = template.get("form_namespace", "stories")
        form_submit = template.get("form_submit_text", "Submit")
        content_section = f"""
      <section>
        <h1>{headline}</h1>
        <p>{tagline}</p>

        {{{{ render_form | namespace: '{form_namespace}' | submit_text: '{form_submit}' }}}}
      </section>
"""
    elif page_type == "category":
        content_section = f"""
      <section>
        <h1>{headline}</h1>
        <p>{tagline}</p>

        <div class="content">
          {main_content}
        </div>
      </section>
"""
    else:
        content_section = f"""
      <section>
        <h1>{headline}</h1>
        {f'<p>{tagline}</p>' if tagline else ''}
        <div class="content">
          {main_content}
        </div>
      </section>
"""

    # Validate no forbidden tags
    is_valid, errors = validate_liquid_content(content_section)
    if not is_valid:
        return {
            "error": "Generated content contains forbidden Liquid tags",
            "forbidden_tags_found": errors,
            "fix": "Remove forbidden tags and use verified alternatives",
        }

    # Build complete HTML
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{site_title}</title>
  <style>
{css}
  </style>
</head>
<body>
  <div class="container">
    <header>
      <nav>
{nav_html}
      </nav>
    </header>

    <main>
{content_section}
    </main>

    <footer>
      <p>{footer_text}</p>
    </footer>
  </div>
</body>
</html>
"""

    return {
        "html": html,
        "page_type": page_type,
        "slots_filled": list(slot_values.keys()),
        "style": "90s_nostalgia",
        "validated": True,
        "next_step": "Create page using create_page tool, then verify with verify_page",
    }


def create_template_designer_subagent():
    """Create the Template Designer subagent."""
    model = ChatAnthropic(
        model="claude-sonnet-4-20250514",
        temperature=0,
    )

    tools = [
        list_templates,
        select_template,
        get_liquid_tag,
        generate_styled_page,
        verify_page,
    ]

    return create_react_agent(
        model,
        tools,
        state_modifier=TEMPLATE_SUBAGENT_PROMPT,
    )


# Export for use in main agent
__all__ = [
    "create_template_designer_subagent",
    "list_templates",
    "select_template",
    "get_liquid_tag",
    "generate_styled_page",
    "verify_page",
    "VERIFIED_LIQUID_TAGS",
    "FORBIDDEN_TAGS",
    "BLOG_TEMPLATES",
]
