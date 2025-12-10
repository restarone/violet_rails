"""Specification generation tools."""

import json
from typing import Optional

import yaml
from langchain_core.tools import tool
from pydantic import BaseModel, Field


class NamespaceSpec(BaseModel):
    """Specification for an API namespace."""

    name: str = Field(description="Human-readable name, e.g., 'Pet'")
    slug: str = Field(description="URL-safe slug, e.g., 'pets'")
    properties: dict[str, str] = Field(description="Property name to type mapping")
    relationships: list[dict] = Field(default_factory=list)


class AppSpec(BaseModel):
    """Complete application specification."""

    subdomain_name: str = Field(description="Lowercase subdomain, e.g., 'pet-adoption'")
    app_title: str = Field(description="Human-readable title")
    description: Optional[str] = None
    namespaces: list[NamespaceSpec]
    pages: list[dict] = Field(default_factory=list)


@tool
def generate_specification(
    subdomain_name: str,
    app_title: str,
    description: str,
    namespaces_json: str,
    pages_json: str = "[]",
) -> str:
    """
    Generate a complete app specification in YAML format.

    Use this after gathering requirements to create a structured spec
    that can be presented to the user for approval.

    Args:
        subdomain_name: Lowercase subdomain name (e.g., 'pet-adoption')
        app_title: Human-readable app title (e.g., 'Pet Adoption Platform')
        description: Brief description of what the app does
        namespaces_json: JSON array of namespace definitions, each with:
            - name: String (e.g., "Pet")
            - slug: String (e.g., "pets")
            - properties: Object of property_name: type
            - relationships: Array of relationship definitions (optional)
        pages_json: JSON array of page definitions (optional), each with:
            - type: "index" | "show" | "form"
            - namespace: slug of the namespace
            - title: page title (optional)

    Returns:
        Formatted YAML specification ready for user review
    """
    # Validate and clean subdomain name
    clean_subdomain = subdomain_name.lower().replace(" ", "-").replace("_", "-")
    # Remove any characters that aren't alphanumeric or hyphens
    clean_subdomain = "".join(c for c in clean_subdomain if c.isalnum() or c == "-")
    # Ensure it starts with a letter
    if clean_subdomain and not clean_subdomain[0].isalpha():
        clean_subdomain = "app-" + clean_subdomain

    try:
        namespaces = json.loads(namespaces_json)
        pages = json.loads(pages_json)
    except json.JSONDecodeError as e:
        return f"Error parsing JSON: {e}\n\nPlease check your namespace and page definitions."

    # Build the specification
    spec = {
        "subdomain_name": clean_subdomain,
        "app_title": app_title,
        "description": description,
        "namespaces": namespaces,
        "pages": pages,
    }

    # Format as YAML
    yaml_output = yaml.dump(spec, default_flow_style=False, sort_keys=False, allow_unicode=True)

    # Count entities for summary
    num_namespaces = len(namespaces)
    num_properties = sum(len(ns.get("properties", {})) for ns in namespaces)
    num_pages = len(pages)

    return f"""## Generated App Specification

```yaml
{yaml_output}```

### Summary
- **{num_namespaces}** data model{"s" if num_namespaces != 1 else ""}
- **{num_properties}** total properties
- **{num_pages}** page{"s" if num_pages != 1 else ""}

---

**Review this specification.** Reply with:
- **"create"** or **"yes"** to build this app
- **"adjust [your changes]"** to modify the spec
"""
