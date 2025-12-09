"""Subdomain creation tools - uses direct Rails model access.

DHH-approved pattern: Direct model access via rails runner instead of
non-existent API endpoints. This is the Rails way.
"""

import os
import re

from langchain_core.tools import tool

from violet_app_agent.tools.rails_runner import create_subdomain as rails_create_subdomain

APP_HOST = os.getenv("APP_HOST", "localhost:5250")


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

    # Use Rails runner for direct model access (DHH-approved)
    success, result = rails_create_subdomain(subdomain_name)

    if success:
        return f"""✓ Subdomain created successfully!

**App URL:** http://{subdomain_name}.{APP_HOST}
**Admin Panel:** http://{subdomain_name}.{APP_HOST}/admin

{result}
"""
    else:
        if "already been taken" in result.lower():
            return f"Error: Subdomain '{subdomain_name}' already exists."
        return f"Error creating subdomain: {result}"
