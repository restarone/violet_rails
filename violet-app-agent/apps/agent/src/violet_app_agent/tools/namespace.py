"""API Namespace creation tools - uses direct Rails model access.

DHH-approved pattern: Direct model access via rails runner instead of
non-existent API endpoints. This is the Rails way.
"""

import json
import os

from langchain_core.tools import tool

from .rails_runner import create_api_namespace as rails_create_namespace

APP_HOST = os.getenv("APP_HOST", "localhost:5250")

# Valid property types in Violet Rails
VALID_PROPERTY_TYPES = {
    "String",
    "Text",
    "Integer",
    "Float",
    "Boolean",
    "Date",
    "DateTime",
    "Array",
}


@tool
def create_namespace(
    subdomain: str,
    name: str,
    slug: str,
    properties_json: str,
    is_renderable: bool = True,
) -> str:
    """
    Create an API namespace in a subdomain.

    An API namespace is a data model with properties. It automatically gets:
    - CRUD API endpoints
    - Admin interface
    - Optional form generation (if is_renderable=True)

    Args:
        subdomain: Target subdomain name (must exist)
        name: Human-readable namespace name (e.g., 'Pet', 'Booking')
        slug: URL-safe slug (e.g., 'pets', 'bookings')
        properties_json: JSON object mapping property names to types.
            Valid types: String, Text, Integer, Float, Boolean, Date, DateTime, Array
            Example: '{"name": "String", "age": "Integer", "active": "Boolean"}'
        is_renderable: If true, auto-generates forms for this namespace

    Returns:
        Success message with property count, or error message
    """
    # Parse properties
    try:
        properties = json.loads(properties_json)
    except json.JSONDecodeError as e:
        return f"Error parsing properties JSON: {e}"

    # Validate properties
    if not isinstance(properties, dict):
        return "Error: properties_json must be a JSON object (dict), not an array."

    if not properties:
        return "Error: At least one property is required."

    # Validate property types
    invalid_types = []
    for prop_name, prop_type in properties.items():
        if prop_type not in VALID_PROPERTY_TYPES:
            invalid_types.append(f"  - {prop_name}: '{prop_type}' (not valid)")

    if invalid_types:
        valid_list = ", ".join(sorted(VALID_PROPERTY_TYPES))
        return (
            f"Error: Invalid property types found:\n"
            + "\n".join(invalid_types)
            + f"\n\nValid types are: {valid_list}"
        )

    # Use Rails runner for direct model access (DHH-approved)
    success, result = rails_create_namespace(subdomain, name, slug, properties)

    if success:
        form_note = " (form auto-generated)" if is_renderable else ""
        return f"""✓ API namespace '{name}' created with {len(properties)} properties{form_note}

**API Endpoint:** http://{subdomain}.{APP_HOST}/api/v1/{slug}/
**Admin Panel:** http://{subdomain}.{APP_HOST}/api_namespaces

{result}
"""
    else:
        if "doesn't exist" in result.lower() or "not found" in result.lower():
            return f"Error: Subdomain '{subdomain}' not found. Create it first."
        if "already been taken" in result.lower():
            return f"Error: API namespace '{slug}' already exists in subdomain '{subdomain}'."
        return f"Error creating namespace: {result}"
