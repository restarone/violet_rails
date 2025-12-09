"""Main Violet App Builder agent definition.

Designed for non-technical users to build web apps through conversation:
- Natural language app descriptions
- Automatic schema generation
- CMS page creation
- GitHub deployment
"""

import argparse
import os

from deepagents import create_deep_agent
from langchain_anthropic import ChatAnthropic

from violet_app_agent.prompts import QUICK_QUESTIONS, SYSTEM_PROMPT, print_welcome
from violet_app_agent.subagents import (
    architect_subagent,
    cms_designer_subagent,
    content_researcher_subagent,
    deployer_subagent,
    security_subagent,
    create_template_designer_subagent,
    list_templates,
    select_template,
    get_liquid_tag,
    generate_styled_page,
    verify_page,
)
from violet_app_agent.tools import (
    create_namespace,
    create_page,
    create_subdomain,
    diagnose_requirements,
    generate_specification,
    trigger_deployment,
)
from violet_app_agent.tools.rails_runner import check_db_health


def create_violet_app_agent(
    model_name: str = "claude-sonnet-4-20250514",
    use_memory: bool = True,
):
    """
    Create the Violet App Builder agent.

    Args:
        model_name: Model name to use (default: Claude Sonnet 4)
        use_memory: Whether to enable memory/checkpointing

    Returns:
        Configured deep agent instance
    """
    running_in_langgraph_api = os.getenv("LANGGRAPH_API_URL") is not None

    # Create the model instance
    model = ChatAnthropic(model=model_name)

    return create_deep_agent(
        model=model,
        tools=[
            # Requirements and specification
            diagnose_requirements,
            generate_specification,
            # Subdomain and data model creation
            create_subdomain,
            create_namespace,
            # CMS and pages
            create_page,
            # Template Designer tools (deterministic, verified Liquid tags)
            list_templates,
            select_template,
            get_liquid_tag,
            generate_styled_page,
            verify_page,
            # Deployment
            trigger_deployment,
        ],
        subagents=[
            architect_subagent,
            cms_designer_subagent,
            content_researcher_subagent,
            deployer_subagent,
            security_subagent,
            create_template_designer_subagent(),  # Deterministic template generation
        ],
        system_prompt=SYSTEM_PROMPT,
        checkpointer=True if (use_memory and not running_in_langgraph_api) else None,
    )


# Run DB health check at startup (fail fast if DB unavailable)
def _startup_health_check():
    """Check database connectivity at module load time."""
    import sys
    healthy, result = check_db_health()
    if healthy:
        import json
        try:
            status = json.loads(result)
            print(f"[Startup] DB healthy: {status.get('database', 'unknown')} ({status.get('subdomain_count', 0)} subdomains)")
        except json.JSONDecodeError:
            print(f"[Startup] DB check passed: {result}")
    else:
        print(f"[Startup] WARNING: DB health check failed: {result}", file=sys.stderr)
        # Don't exit - allow agent to start but warn loudly

_startup_health_check()

# Default agent instance for LangGraph deployment
agent = create_violet_app_agent()


def main() -> None:
    """Run the agent in interactive mode."""
    parser = argparse.ArgumentParser(description="Violet App Builder CLI")
    parser.add_argument(
        "--stream",
        action="store_true",
        help="Enable streaming mode for real-time feedback",
    )
    args = parser.parse_args()

    print_welcome()

    while True:
        try:
            user_input = input("\nYou: ").strip()

            if not user_input:
                continue

            if user_input.lower() in ["quit", "exit", "q"]:
                print("\nGoodbye! Happy building!")
                break

            # Handle quick picks
            if user_input in QUICK_QUESTIONS:
                user_input = QUICK_QUESTIONS[user_input]
                print(f"→ {user_input}\n")

            # Process the request
            print("\nThinking...")
            result = agent.invoke({"messages": [{"role": "user", "content": user_input}]})

            print("\nViolet App Builder:")
            print(result["messages"][-1].content)

        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            break
        except Exception as e:
            error_msg = str(e)
            if "API" in error_msg or "key" in error_msg.lower():
                print("\n⚠️  API connection issue. Check your ANTHROPIC_API_KEY.")
            elif "rate" in error_msg.lower():
                print("\n⚠️  Rate limited. Please wait a moment.")
            else:
                print(f"\n⚠️  Something went wrong: {e}")
            print("\nTry rephrasing or type 'help' for examples.")


if __name__ == "__main__":
    main()
