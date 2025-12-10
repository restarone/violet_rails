# feat: Web UI Agent for Natural Language App Deployment via GitHub

## Overview

Build a **Deep Agent** for violet_rails that enables users to describe their app idea in natural language and have it automatically configured and deployed. Following the proven PRIW and Trace Mineral agent architecture patterns.

## The 4 Deep Agent Principles Applied

### 1. DIAGNOSE (Understand Before Acting)
- Structured diagnostic questions to understand user's app requirements
- Assess technical complexity, data model needs, deployment preferences
- Score app complexity: Simple (1-2 models) → Complex (6+ models with relationships)

### 2. MULTI-EXPERT (Specialized Subagents)
- **App Architect Subagent** - Designs data models and relationships
- **CMS Designer Subagent** - Creates pages, layouts, forms
- **Deployment Subagent** - Handles GitHub integration and deployment
- **Security Reviewer Subagent** - Validates permissions and safety

### 3. ARTIFACT-FIRST (Concrete Deliverables)
Every session produces:
- App Specification (YAML)
- Subdomain configuration
- API namespace definitions
- Generated pages and forms
- Deployment workflow (optional)

### 4. DOMAIN-NATIVE (Speak Violet Rails Language)
- "Subdomains" not "tenant instances"
- "API namespaces" not "data models"
- "CMS pages" not "content records"
- Sound like a Rails developer colleague, not a professor

---

## Technical Approach

### Architecture (Following PRIW/Trace Mineral Pattern)

```
violet-app-agent/
├── apps/
│   └── agent/
│       ├── src/violet_app_agent/
│       │   ├── __init__.py
│       │   ├── agent.py              # Main deep agent
│       │   ├── prompts.py            # System prompts (THE MAGIC)
│       │   ├── tools/
│       │   │   ├── __init__.py
│       │   │   ├── diagnostic.py     # App requirements assessment
│       │   │   ├── specification.py  # Generate app specs
│       │   │   ├── subdomain.py      # Create subdomains via API
│       │   │   ├── namespace.py      # Create API namespaces
│       │   │   ├── cms.py            # Create pages/layouts
│       │   │   └── github.py         # GitHub integration
│       │   ├── subagents/
│       │   │   ├── __init__.py
│       │   │   ├── architect.py      # App architecture design
│       │   │   ├── cms_designer.py   # Page/form design
│       │   │   ├── deployer.py       # GitHub/deployment
│       │   │   └── security.py       # Security review
│       │   └── memories/
│       │       ├── violet_architecture.md
│       │       ├── api_patterns.md
│       │       └── cms_templates.md
│       ├── tests/
│       │   ├── test_tools.py
│       │   ├── test_subagents.py
│       │   └── conftest.py
│       ├── pyproject.toml
│       └── .env.example
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── README.md
│   ├── JOBS_TO_BE_DONE.md
│   └── UX_PRINCIPLES.md
│
└── langgraph.json
```

### Core Agent Definition

```python
# apps/agent/src/violet_app_agent/agent.py
"""Violet Rails App Builder - Deep Agent."""

import os
from deepagents import create_deep_agent
from violet_app_agent.prompts import SYSTEM_PROMPT, WELCOME_MESSAGE, QUICK_QUESTIONS
from violet_app_agent.subagents import (
    architect_subagent,
    cms_designer_subagent,
    deployer_subagent,
    security_subagent,
)
from violet_app_agent.tools import (
    diagnose_requirements,
    generate_specification,
    create_subdomain,
    create_namespace,
    create_page,
    trigger_deployment,
)


def create_agent(
    model: str = "anthropic:claude-sonnet-4-20250514",
    use_memory: bool = True,
):
    """Create configured Violet App Builder agent."""
    running_in_langgraph_api = os.getenv("LANGGRAPH_API_URL") is not None

    return create_deep_agent(
        model=model,
        tools=[
            diagnose_requirements,
            generate_specification,
            create_subdomain,
            create_namespace,
            create_page,
            trigger_deployment,
        ],
        subagents=[
            architect_subagent,
            cms_designer_subagent,
            deployer_subagent,
            security_subagent,
        ],
        system_prompt=SYSTEM_PROMPT,
        checkpointer=True if (use_memory and not running_in_langgraph_api) else None,
    )


# Default instance for LangGraph
agent = create_agent()


def print_welcome():
    """Print welcome with examples and quick picks."""
    print(WELCOME_MESSAGE)
    print("\nQuick picks (just type the number):")
    for num, question in QUICK_QUESTIONS.items():
        print(f"  {num}. {question}")


def main():
    """Run agent in interactive mode."""
    print_welcome()
    while True:
        try:
            user_input = input("\nYou: ").strip()
            if user_input.lower() in ("exit", "quit"):
                break
            if user_input in QUICK_QUESTIONS:
                user_input = QUICK_QUESTIONS[user_input]
            result = agent.invoke({"messages": [{"role": "user", "content": user_input}]})
            print(f"\n{result['messages'][-1].content}\n")
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"\n⚠️  Oops: {e}\n")


if __name__ == "__main__":
    main()
```

### System Prompts (The Magic)

```python
# apps/agent/src/violet_app_agent/prompts.py
"""System prompts for Violet App Builder agent."""

SYSTEM_PROMPT = """You are the Violet Rails App Builder, an AI assistant that helps users create web applications on the Violet Rails platform.

## Your Mission
Help users go from "I have an idea" to "I have a working app" in 15 minutes or less. You create subdomains with API namespaces, forms, pages, and optionally deploy via GitHub.

## How to Talk
- Sound like a helpful Rails developer colleague, not a professor
- Use Violet Rails terminology naturally:
  - "subdomain" not "tenant instance"
  - "API namespace" not "data model"
  - "properties" not "fields"
  - "CMS pages" not "content records"
- Keep responses scannable - use bullet points, tables, headers
- Be encouraging but honest about complexity

## Your Process

### Step 1: Understand Requirements
Ask clarifying questions to understand:
- What's the core purpose of the app?
- What are the main data entities?
- What relationships exist between entities?
- Do they need user authentication?
- Any specific pages beyond CRUD?

### Step 2: Generate Specification
Once you understand requirements, generate a spec:

```yaml
subdomain_name: pet-adoption
app_title: Pet Adoption Platform
description: Connect shelters with adopters

namespaces:
  - name: Shelter
    slug: shelters
    properties:
      name: String
      address: String
      phone: String
      email: String

  - name: Pet
    slug: pets
    properties:
      name: String
      species: String
      breed: String
      age: Integer
      description: Text
      available: Boolean
      shelter_id: Integer
    relationships:
      - belongs_to: Shelter

  - name: Application
    slug: applications
    properties:
      applicant_name: String
      email: String
      phone: String
      message: Text
      status: String
      pet_id: Integer
    relationships:
      - belongs_to: Pet

pages:
  - type: index
    namespace: pets
    title: Available Pets
  - type: show
    namespace: pets
  - type: form
    namespace: applications
    title: Apply to Adopt
```

### Step 3: Get Approval
Present the spec in human-readable format and ask:
"Does this look right? I can create this app now, or we can adjust the spec first."

### Step 4: Create Resources
Once approved, use tools to:
1. Create subdomain
2. Create each API namespace
3. Generate forms
4. Create CMS pages

### Step 5: Deployment (Optional)
If user wants GitHub deployment:
1. Generate GitHub Actions workflow
2. Push configuration
3. Trigger deployment

## Response Patterns

### For "I want to build..." questions
1. Ask 2-3 clarifying questions about data and relationships
2. Generate spec based on answers
3. Present for approval

### For specification review
```markdown
## Your App: [App Title]

**Subdomain:** [name].yourdomain.com

### Data Models

**[Model 1]**
- field1: Type
- field2: Type

**[Model 2]**
- field1: Type
- Belongs to: [Model 1]

### Pages
- [Page 1]: [description]
- [Page 2]: [description]

---
Shall I create this app? (yes/adjust)
```

### For creation progress
```markdown
Creating your app...

✓ Subdomain created: [name]
✓ API namespace: [Model1]
✓ API namespace: [Model2]
✓ Form generated: [FormName]
✓ Page created: [PageName]

🎉 Your app is ready!
URL: https://[subdomain].yourdomain.com
Admin: https://[subdomain].yourdomain.com/admin
```

## Property Types
- String: Short text (names, titles)
- Text: Long text (descriptions, content)
- Integer: Whole numbers
- Float: Decimal numbers
- Boolean: True/false
- Date: Date only
- DateTime: Date and time
- Array: List of values

## What NOT to Do
- Don't create apps without user approval
- Don't guess at requirements - ask
- Don't use generic programming terminology
- Don't create overly complex specs for simple apps
- Don't proceed if something is unclear

## Follow-up Suggestions
After completing an app, suggest:
- "Want to add sample data?"
- "Should I set up user authentication?"
- "Would you like to customize the page layouts?"
- "Ready to deploy to production via GitHub?"

## Domain Reference
Violet Rails is a multi-tenant SaaS platform where each subdomain is an isolated app with:
- Schema-based database isolation (Apartment gem)
- CMS for pages and layouts (Comfy)
- API namespaces for data models (JSONB properties)
- Forms auto-generated from properties
- User authentication per subdomain
- Built-in analytics, email, forums
"""

WELCOME_MESSAGE = """
╔═══════════════════════════════════════════════════════════╗
║           🚀 Violet Rails App Builder                      ║
║                                                            ║
║   Describe your app idea and I'll create it for you.      ║
║   From idea to working app in 15 minutes.                 ║
╚═══════════════════════════════════════════════════════════╝

Examples:
• "I want a recipe sharing app where users can post recipes"
• "Build me a job board for a small company"
• "Create a simple inventory tracker for my store"
"""

QUICK_QUESTIONS = {
    "1": "I want to build a blog with comments",
    "2": "Create a simple contact form app",
    "3": "Build an inventory management system",
    "4": "Make a booking/reservation app",
    "5": "Create a customer feedback collection app",
}
```

### Tools Implementation

```python
# apps/agent/src/violet_app_agent/tools/diagnostic.py
"""Diagnostic tools for understanding app requirements."""

from langchain_core.tools import tool
from typing import Literal


@tool
def diagnose_requirements(
    app_description: str,
    complexity_estimate: Literal["simple", "medium", "complex"] = "medium",
) -> str:
    """
    Analyze an app description and extract key requirements.

    Args:
        app_description: User's description of their app idea
        complexity_estimate: Estimated complexity level

    Returns:
        Structured analysis of requirements
    """
    # This would call an LLM to analyze, but for now return structured prompt
    return f"""
## Requirements Analysis

**Description:** {app_description}
**Estimated Complexity:** {complexity_estimate}

### Suggested Questions to Ask:
1. What are the main things (entities) this app tracks?
2. How do these things relate to each other?
3. Who are the users and what can they do?
4. Any specific pages or views needed?

### Initial Assessment:
- Primary entities detected: [To be filled by LLM reasoning]
- Potential relationships: [To be filled]
- Suggested property types: [To be filled]
"""
```

```python
# apps/agent/src/violet_app_agent/tools/specification.py
"""Specification generation tools."""

import json
import yaml
from langchain_core.tools import tool
from pydantic import BaseModel
from typing import Optional


class NamespaceSpec(BaseModel):
    name: str
    slug: str
    properties: dict[str, str]
    relationships: list[dict] = []


class AppSpec(BaseModel):
    subdomain_name: str
    app_title: str
    description: Optional[str] = None
    namespaces: list[NamespaceSpec]
    pages: list[dict] = []


@tool
def generate_specification(
    subdomain_name: str,
    app_title: str,
    description: str,
    namespaces_json: str,
    pages_json: str = "[]",
) -> str:
    """
    Generate a complete app specification.

    Args:
        subdomain_name: Lowercase subdomain name (e.g., 'pet-adoption')
        app_title: Human-readable app title
        description: Brief description of the app
        namespaces_json: JSON array of namespace definitions
        pages_json: JSON array of page definitions

    Returns:
        YAML specification for the app
    """
    try:
        namespaces = json.loads(namespaces_json)
        pages = json.loads(pages_json)

        spec = {
            "subdomain_name": subdomain_name.lower().replace(" ", "-"),
            "app_title": app_title,
            "description": description,
            "namespaces": namespaces,
            "pages": pages,
        }

        return f"""## Generated App Specification

```yaml
{yaml.dump(spec, default_flow_style=False, sort_keys=False)}
```

**Review this specification.** Reply with:
- "create" to build this app
- "adjust [changes]" to modify the spec
"""
    except json.JSONDecodeError as e:
        return f"Error parsing specification: {e}"
```

```python
# apps/agent/src/violet_app_agent/tools/subdomain.py
"""Subdomain creation tools - calls Violet Rails API."""

import os
import httpx
from langchain_core.tools import tool


VIOLET_API_URL = os.getenv("VIOLET_API_URL", "http://localhost:5250")
VIOLET_API_KEY = os.getenv("VIOLET_API_KEY", "")


@tool
def create_subdomain(subdomain_name: str) -> str:
    """
    Create a new subdomain on Violet Rails.

    Args:
        subdomain_name: Lowercase subdomain name (1-63 chars, alphanumeric + hyphens)

    Returns:
        Success message with subdomain URL or error
    """
    # Validate name format
    import re
    if not re.match(r'^[a-z](?:[a-z0-9-]*[a-z0-9])?$', subdomain_name):
        return f"Error: Invalid subdomain name '{subdomain_name}'. Must start with letter, contain only lowercase letters, numbers, hyphens."

    if len(subdomain_name) > 63:
        return f"Error: Subdomain name too long ({len(subdomain_name)} chars). Max 63."

    try:
        response = httpx.post(
            f"{VIOLET_API_URL}/api/v1/subdomains",
            headers={"Authorization": f"Bearer {VIOLET_API_KEY}"},
            json={"subdomain": {"name": subdomain_name}},
            timeout=30.0,
        )

        if response.status_code == 201:
            data = response.json()
            return f"""✓ Subdomain created successfully!

**URL:** https://{subdomain_name}.{os.getenv('APP_HOST', 'localhost:5250')}
**Admin:** https://{subdomain_name}.{os.getenv('APP_HOST', 'localhost:5250')}/admin
"""
        elif response.status_code == 422:
            return f"Error: Subdomain '{subdomain_name}' already exists or is invalid."
        else:
            return f"Error creating subdomain: {response.status_code} - {response.text}"

    except httpx.RequestError as e:
        return f"Error connecting to Violet Rails: {e}"
```

```python
# apps/agent/src/violet_app_agent/tools/namespace.py
"""API Namespace creation tools."""

import os
import json
import httpx
from langchain_core.tools import tool


VIOLET_API_URL = os.getenv("VIOLET_API_URL", "http://localhost:5250")
VIOLET_API_KEY = os.getenv("VIOLET_API_KEY", "")


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

    Args:
        subdomain: Target subdomain name
        name: Human-readable namespace name (e.g., 'Pet')
        slug: URL slug (e.g., 'pets')
        properties_json: JSON object of property definitions
        is_renderable: Whether to generate forms/views

    Returns:
        Success message or error
    """
    try:
        properties = json.loads(properties_json)
    except json.JSONDecodeError as e:
        return f"Error parsing properties: {e}"

    try:
        response = httpx.post(
            f"{VIOLET_API_URL}/api/v1/namespaces",
            headers={
                "Authorization": f"Bearer {VIOLET_API_KEY}",
                "X-Subdomain": subdomain,
            },
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
            return f"✓ API namespace '{name}' created with {len(properties)} properties"
        else:
            return f"Error creating namespace: {response.status_code} - {response.text}"

    except httpx.RequestError as e:
        return f"Error connecting to Violet Rails: {e}"
```

### Subagents

```python
# apps/agent/src/violet_app_agent/subagents/architect.py
"""App Architect subagent - designs data models and relationships."""

from deepagents import SubAgent
from ..tools import diagnose_requirements, generate_specification

ARCHITECT_PROMPT = """You are the App Architect for Violet Rails.

## Your Role
Design clean, efficient data models for web applications. You understand:
- Entity-relationship modeling
- Proper normalization
- JSONB property types in Violet Rails
- Relationship patterns (has_many, belongs_to)

## How to Work
1. Analyze the app requirements
2. Identify core entities
3. Define properties with appropriate types
4. Establish relationships
5. Keep it simple - don't over-engineer

## Property Type Guide
- String: names, titles, short text (< 255 chars)
- Text: descriptions, content, long text
- Integer: counts, IDs, whole numbers
- Float: prices, measurements, decimals
- Boolean: flags, toggles, yes/no
- Date: birthdays, due dates
- DateTime: timestamps, scheduled times
- Array: tags, categories, lists

## Relationship Patterns
- belongs_to: Store foreign key (e.g., pet belongs_to shelter)
- has_many: Inverse relationship (shelter has_many pets)

## What NOT to Do
- Don't create circular dependencies
- Don't over-normalize for simple apps
- Don't add fields "just in case"
- Don't use complex types when simple ones work
"""

architect_subagent: SubAgent = {
    "name": "app-architect",
    "description": """Use this subagent for:
- Designing data models from app descriptions
- Figuring out entity relationships
- Choosing appropriate property types
- Reviewing and improving specifications

The architect focuses on clean data modeling.""",
    "system_prompt": ARCHITECT_PROMPT,
    "tools": [diagnose_requirements, generate_specification],
}
```

```python
# apps/agent/src/violet_app_agent/subagents/deployer.py
"""Deployer subagent - handles GitHub integration and deployment."""

from deepagents import SubAgent
from ..tools import trigger_deployment

DEPLOYER_PROMPT = """You are the Deployment Specialist for Violet Rails.

## Your Role
Handle GitHub integration and deployment workflows. You:
- Generate GitHub Actions workflows
- Push configurations to repositories
- Trigger deployment pipelines
- Monitor deployment status

## Deployment Options
1. **Local Development** - No deployment needed, app runs on local Violet Rails
2. **GitHub Actions** - Push to repo, trigger workflow
3. **Heroku** - One-click deployment via workflow
4. **AWS EC2** - Capistrano-based deployment

## What NOT to Do
- Don't deploy without user confirmation
- Don't push to production without review
- Don't expose credentials in logs
- Don't skip security checks
"""

deployer_subagent: SubAgent = {
    "name": "deployer",
    "description": """Use this subagent for:
- Setting up GitHub repository integration
- Generating deployment workflows
- Triggering deployments
- Checking deployment status

The deployer handles all GitHub and deployment operations.""",
    "system_prompt": DEPLOYER_PROMPT,
    "tools": [trigger_deployment],
}
```

### Configuration

```toml
# apps/agent/pyproject.toml
[project]
name = "violet-app-agent"
version = "0.1.0"
description = "Deep Agent for building apps on Violet Rails"
requires-python = ">=3.11"
dependencies = [
    "deepagents>=0.2.0",
    "langchain>=0.3.0",
    "langchain-anthropic>=0.3.0",
    "langgraph>=0.2.0",
    "httpx>=0.27.0",
    "pyyaml>=6.0",
    "pydantic>=2.0.0",
    "python-dotenv>=1.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-httpx>=0.30.0",
    "ruff>=0.5.0",
]

[project.scripts]
violet-agent = "violet_app_agent.agent:main"

[tool.ruff]
line-length = 100
target-version = "py311"
```

```json
// langgraph.json
{
  "python_version": "3.11",
  "dependencies": ["./apps/agent"],
  "graphs": {
    "violet-app-agent": "./apps/agent/src/violet_app_agent/agent:agent"
  },
  "env": "./apps/agent/.env"
}
```

```bash
# apps/agent/.env.example
ANTHROPIC_API_KEY=sk-ant-...
VIOLET_API_URL=http://localhost:5250
VIOLET_API_KEY=your-violet-api-key
APP_HOST=localhost:5250
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create agent package structure
- [ ] Write system prompts (prompts.py)
- [ ] Implement diagnostic tool
- [ ] Implement specification generator
- [ ] Basic tests for tools

### Phase 2: Violet Rails Integration (Week 1-2)
- [ ] Create subdomain API endpoint in Rails
- [ ] Create namespace API endpoint in Rails
- [ ] Implement subdomain tool
- [ ] Implement namespace tool
- [ ] Integration tests with mocked API

### Phase 3: Subagents (Week 2)
- [ ] Implement architect subagent
- [ ] Implement CMS designer subagent
- [ ] Implement deployer subagent
- [ ] Implement security reviewer subagent

### Phase 4: Testing & Polish (Week 2-3)
- [ ] E2E tests with live LLM
- [ ] Error handling refinement
- [ ] Documentation (ARCHITECTURE.md, README.md)
- [ ] LangGraph Cloud deployment config

---

## Rails API Endpoints to Create

The agent needs these API endpoints in violet_rails:

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :subdomains, only: [:create, :show]
    resources :namespaces, only: [:create, :index, :show]
    resources :pages, only: [:create]
    resources :deployments, only: [:create, :show]
  end
end
```

```ruby
# app/controllers/api/v1/subdomains_controller.rb
class Api::V1::SubdomainsController < Api::BaseController
  before_action :authenticate_api_key!

  def create
    subdomain = Subdomain.new(subdomain_params)

    if subdomain.save
      # Bootstrap CMS site
      Apartment::Tenant.switch(subdomain.name) do
        # Create default layout and page
      end

      render json: {
        name: subdomain.name,
        url: "https://#{subdomain.name}.#{ENV['APP_HOST']}"
      }, status: :created
    else
      render json: { errors: subdomain.errors }, status: :unprocessable_entity
    end
  end

  private

  def subdomain_params
    params.require(:subdomain).permit(:name)
  end
end
```

---

## Documentation to Create

### docs/ARCHITECTURE.md
- Deep Agent principles applied
- Tool and subagent design
- API integration patterns
- Deployment architecture

### docs/JOBS_TO_BE_DONE.md
```markdown
## User Personas

### 1. Non-Technical Founder
**Situation:** Has an app idea but no coding skills
**Motivation:** Launch MVP quickly to validate idea
**Outcome:** Working app with CRUD and basic pages

### 2. Rails Developer
**Situation:** Needs to spin up prototypes quickly
**Motivation:** Skip boilerplate, focus on business logic
**Outcome:** Scaffolded app ready for customization

### 3. Agency/Consultant
**Situation:** Client needs custom app fast
**Motivation:** Deliver value quickly, iterate later
**Outcome:** White-label app deployed to client subdomain
```

### docs/UX_PRINCIPLES.md
Following PRIW's "Don't Make Me Think" approach:
- Quick picks for common app types
- Minimal questions, maximum inference
- Progressive disclosure of complexity
- Clear progress indicators
- Actionable error messages

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Time to working app | <15 min | From first message to app URL |
| Specification accuracy | >90% | User accepts spec without changes |
| Creation success rate | >95% | Apps created without errors |
| User satisfaction | >4.5/5 | Post-creation feedback |

---

## References

### Deep Agent Reference Implementations
- PRIW Agent: `/Users/shambhavi/Documents/projects/priw`
- Trace Mineral Agent: `/Users/shambhavi/Documents/projects/trace-mineral-agent`

### Violet Rails
- Project: `/Users/shambhavi/Documents/projects/violet_rails`
- Subdomain model: `app/models/subdomain.rb`
- API namespace model: `app/models/api_namespace.rb`
- Existing API: `app/controllers/api/base_controller.rb`

### Tech Stack
- Backend: Python 3.11+, deepagents, LangGraph
- LLM: Claude Sonnet 4 (claude-sonnet-4-20250514)
- Deployment: LangGraph Cloud
- Testing: pytest with httpx mocking

---

**Generated with Claude Code**
