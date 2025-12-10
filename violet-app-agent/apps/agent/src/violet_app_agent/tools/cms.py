"""CMS page creation tools - uses direct Rails model access.

DHH-approved pattern: Direct model access via rails runner instead of
non-existent API endpoints. This is the Rails way.
"""

import os
from typing import Literal

from langchain_core.tools import tool

from violet_app_agent.tools.rails_runner import create_cms_page as rails_create_page

APP_HOST = os.getenv("APP_HOST", "localhost:5250")


@tool
def create_page(
    subdomain: str,
    title: str,
    slug: str,
    page_type: Literal["index", "show", "form", "custom"] = "custom",
    namespace_slug: str = "",
    content: str = "",
) -> str:
    """
    Create a CMS page in a subdomain.

    Pages are created in the Comfy CMS system and can display:
    - API namespace listings (index)
    - API namespace detail views (show)
    - API forms for data entry (form)
    - Custom content (custom)

    Args:
        subdomain: Target subdomain name
        title: Page title displayed in browser and navigation
        slug: URL path for the page (e.g., 'pets' becomes /pets)
        page_type: Type of page to create:
            - "index": List view of namespace resources
            - "show": Detail view of a single resource
            - "form": Data entry form for a namespace
            - "custom": Custom content page
        namespace_slug: Required for index/show/form pages. The API namespace slug.
        content: Custom HTML/template content. Used for "custom" type.
            For other types, content is auto-generated.

    Returns:
        Success message with page URL, or error message
    """
    # Validate namespace_slug for non-custom pages
    if page_type in ("index", "show", "form") and not namespace_slug:
        return f"Error: namespace_slug is required for '{page_type}' pages."

    # Generate content based on page type
    if page_type == "index":
        generated_content = f"{{{{ cms:helper render_api_namespace_resource_index '{namespace_slug}' }}}}"
    elif page_type == "show":
        generated_content = f"{{{{ cms:helper render_api_namespace_resource '{namespace_slug}' }}}}"
    elif page_type == "form":
        generated_content = f"{{{{ cms:helper render_api_form '{namespace_slug}' }}}}"
    else:
        generated_content = content or "<p>Welcome to your new page!</p>"

    # Use Rails runner for direct model access (DHH-approved)
    success, result = rails_create_page(subdomain, title, slug, generated_content)

    if success:
        return f"""✓ Page '{title}' created successfully!

**Page URL:** http://{subdomain}.{APP_HOST}/{slug}
**Admin Panel:** http://{subdomain}.{APP_HOST}/admin/cms

{result}
"""
    else:
        if "doesn't exist" in result.lower() or "not found" in result.lower():
            return f"Error: Subdomain '{subdomain}' not found."
        if "No CMS site found" in result:
            return f"Error: CMS not initialized for subdomain '{subdomain}'."
        return f"Error creating page: {result}"
