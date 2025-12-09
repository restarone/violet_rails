"""Diagnostic tools for understanding app requirements."""

from typing import Literal

from langchain_core.tools import tool


@tool
def diagnose_requirements(
    app_description: str,
    complexity_estimate: Literal["simple", "medium", "complex"] = "medium",
) -> str:
    """
    Analyze an app description and extract key requirements.

    Use this to structure your thinking about what the user wants to build.
    It helps identify entities, relationships, and clarifying questions.

    Args:
        app_description: User's natural language description of their app idea
        complexity_estimate: Your estimate of app complexity based on description

    Returns:
        Structured analysis with suggested questions and initial entity detection
    """
    # Complexity scoring
    complexity_hints = {
        "simple": "1-2 data models, basic CRUD, no complex relationships",
        "medium": "3-5 data models, some relationships, standard pages",
        "complex": "6+ data models, complex relationships, custom workflows",
    }

    return f"""## Requirements Analysis

**User Description:** {app_description}

**Estimated Complexity:** {complexity_estimate}
_{complexity_hints[complexity_estimate]}_

### Suggested Clarifying Questions

Based on the description, consider asking about:

1. **Core entities** - What are the main things this app tracks?
2. **Relationships** - How do these things connect to each other?
3. **Users** - Who uses this app and what can they do?
4. **Key pages** - Any specific views beyond standard CRUD?

### Initial Entity Detection

From the description, potential entities might include:
- [Analyze the description for nouns that could be data models]
- [Look for relationships indicated by verbs like "has", "belongs to", "contains"]

### Recommended Approach

For a {complexity_estimate} app:
- Start with the core entity first
- Add relationships one at a time
- Keep properties minimal initially
- User can always add more later

Use this analysis to guide your clarifying questions before generating a specification.
"""
