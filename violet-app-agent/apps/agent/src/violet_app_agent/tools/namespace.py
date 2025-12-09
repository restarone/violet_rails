"""API Namespace creation tools."""

import json
import os

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

    # Make API request
    try:
        response = httpx.post(
            f"{VIOLET_API_URL}/api/v1/namespaces",
            headers=_get_api_headers(subdomain),
            json={
                "api_namespace": {
                    "name": name,
                    "slug": slug,
                    "version": 1,
                    "properties": properties,
                    "is_renderable": is_renderable,
                    "requires_authentication": False,
                }
            },
            timeout=30.0,
        )

        if response.status_code == 201:
            form_note = " (form auto-generated)" if is_renderable else ""
            return f"✓ API namespace '{name}' created with {len(properties)} properties{form_note}"
        elif response.status_code == 422:
            errors = response.json().get("errors", {})
            return f"Error creating namespace: {errors}"
        elif response.status_code == 404:
            return f"Error: Subdomain '{subdomain}' not found. Create it first."
        elif response.status_code == 401:
            return "Error: Unauthorized. Please check your API key."
        else:
            return f"Error creating namespace: {response.status_code} - {response.text}"

    except httpx.ConnectError:
        return f"Error: Could not connect to Violet Rails at {VIOLET_API_URL}"
    except httpx.TimeoutException:
        return "Error: Request timed out."
    except httpx.RequestError as e:
        return f"Error connecting to Violet Rails: {e}"
