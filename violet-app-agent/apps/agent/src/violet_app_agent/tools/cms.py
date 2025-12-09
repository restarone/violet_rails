"""CMS page creation tools."""

import os
from typing import Literal

import httpx
from langchain_core.tools import tool

VIOLET_API_URL = os.getenv("VIOLET_API_URL", "http://localhost:5250")
VIOLET_API_KEY = os.getenv("VIOLET_API_KEY", "")


def _get_api_headers(subdomain: str) -> dict:
    """Get API headers with subdomain context."""
    return {
        "Authorization": f"Bearer {VIOLET_API_KEY}",
        "Content-Type": "application/json",
        "X-Subdomain": subdomain,
    }


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
        # Show pages are typically handled dynamically
        generated_content = f"{{{{ cms:helper render_api_namespace_resource '{namespace_slug}' }}}}"
    elif page_type == "form":
        # Form pages embed the namespace form
        generated_content = f"{{{{ cms:helper render_api_form '{namespace_slug}' }}}}"
    else:
        generated_content = content or "<p>Welcome to your new page!</p>"

    try:
        response = httpx.post(
            f"{VIOLET_API_URL}/api/v1/pages",
            headers=_get_api_headers(subdomain),
            json={
                "page": {
                    "title": title,
                    "slug": slug,
                    "type": page_type,
                    "namespace_slug": namespace_slug,
                    "content": generated_content,
                }
            },
            timeout=30.0,
        )

        if response.status_code == 201:
            data = response.json()
            page_url = data.get("url", f"/{slug}")
            return f"✓ Page '{title}' created at {page_url}"
        elif response.status_code == 422:
            errors = response.json().get("errors", {})
            return f"Error creating page: {errors}"
        elif response.status_code == 404:
            return f"Error: Subdomain '{subdomain}' not found."
        elif response.status_code == 401:
            return "Error: Unauthorized. Please check your API key."
        else:
            return f"Error creating page: {response.status_code} - {response.text}"

    except httpx.ConnectError:
        return f"Error: Could not connect to Violet Rails at {VIOLET_API_URL}"
    except httpx.TimeoutException:
        return "Error: Request timed out."
    except httpx.RequestError as e:
        return f"Error connecting to Violet Rails: {e}"
