"""Subdomain creation tools - calls Violet Rails API."""

import os
import re

import httpx
from langchain_core.tools import tool

VIOLET_API_URL = os.getenv("VIOLET_API_URL", "http://localhost:5250")
VIOLET_API_KEY = os.getenv("VIOLET_API_KEY", "")
APP_HOST = os.getenv("APP_HOST", "localhost:5250")


def _get_api_headers() -> dict:
    """Get standard API headers."""
    return {
        "Authorization": f"Bearer {VIOLET_API_KEY}",
        "Content-Type": "application/json",
    }


@tool
def create_subdomain(subdomain_name: str) -> str:
    """
    Create a new subdomain on Violet Rails.

    This creates an isolated app environment with its own:
    - Database schema
    - CMS pages and layouts
    - Users and permissions
    - API endpoints

    Args:
        subdomain_name: Lowercase subdomain name (1-63 chars).
            Must start with a letter, contain only lowercase letters,
            numbers, and hyphens. No trailing hyphens.

    Returns:
        Success message with subdomain URL, or error message
    """
    # Validate name format
    if not re.match(r"^[a-z](?:[a-z0-9-]*[a-z0-9])?$", subdomain_name):
        return (
            f"Error: Invalid subdomain name '{subdomain_name}'.\n\n"
            "Requirements:\n"
            "- Must start with a lowercase letter\n"
            "- Can contain lowercase letters, numbers, and hyphens\n"
            "- Cannot end with a hyphen\n"
            "- No spaces or special characters\n\n"
            "Example: 'my-cool-app' or 'petshop'"
        )

    if len(subdomain_name) > 63:
        return f"Error: Subdomain name too long ({len(subdomain_name)} chars). Maximum is 63."

    if len(subdomain_name) < 1:
        return "Error: Subdomain name cannot be empty."

    try:
        response = httpx.post(
            f"{VIOLET_API_URL}/api/v1/subdomains",
            headers=_get_api_headers(),
            json={"subdomain": {"name": subdomain_name}},
            timeout=30.0,
        )

        if response.status_code == 201:
            return f"""✓ Subdomain created successfully!

**App URL:** https://{subdomain_name}.{APP_HOST}
**Admin Panel:** https://{subdomain_name}.{APP_HOST}/admin
"""
        elif response.status_code == 422:
            errors = response.json().get("errors", {})
            if "name" in errors:
                error_msg = errors["name"]
                if isinstance(error_msg, list):
                    error_msg = ", ".join(error_msg)
                return f"Error: Subdomain name issue - {error_msg}"
            return f"Error: Subdomain '{subdomain_name}' already exists or is invalid."
        elif response.status_code == 401:
            return "Error: Unauthorized. Please check your API key configuration."
        else:
            return f"Error creating subdomain: {response.status_code} - {response.text}"

    except httpx.ConnectError:
        return (
            f"Error: Could not connect to Violet Rails at {VIOLET_API_URL}.\n"
            "Please ensure the server is running."
        )
    except httpx.TimeoutException:
        return "Error: Request timed out. The server might be busy."
    except httpx.RequestError as e:
        return f"Error connecting to Violet Rails: {e}"
