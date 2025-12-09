"""Rails Runner utility for direct model access.

DHH-approved pattern: Instead of hitting non-existent API endpoints,
execute Ruby code directly via `rails runner`.

This is the Rails way - direct model access is simpler and more reliable
than building API wrappers for admin operations.
"""

import os
import subprocess
import json
from typing import Optional, Tuple

RAILS_ROOT = os.getenv("RAILS_ROOT", "/Users/shambhavi/Documents/projects/violet_rails")

# Database configuration for local development
RAILS_ENV = {
    "DATABASE_HOST": os.getenv("DATABASE_HOST", "localhost"),
    "DATABASE_PORT": os.getenv("DATABASE_PORT", "6000"),
    "DATABASE_USERNAME": os.getenv("DATABASE_USERNAME", "postgres"),
    "DATABASE_PASSWORD": os.getenv("DATABASE_PASSWORD", "password"),
    "DATABASE_NAME": os.getenv("DATABASE_NAME", "r_solutions_development"),
    "REDIS_URL": os.getenv("REDIS_URL", "redis://localhost:6380/0"),
}


def run_rails_code(ruby_code: str, timeout: int = 30) -> Tuple[bool, str]:
    """
    Execute Ruby code via `rails runner`.

    Args:
        ruby_code: Ruby code to execute
        timeout: Timeout in seconds

    Returns:
        Tuple of (success: bool, output: str)
    """
    env = os.environ.copy()
    env.update(RAILS_ENV)

    try:
        result = subprocess.run(
            ["bin/rails", "runner", ruby_code],
            cwd=RAILS_ROOT,
            env=env,
            capture_output=True,
            text=True,
            timeout=timeout,
        )

        if result.returncode == 0:
            return True, result.stdout.strip()
        else:
            return False, result.stderr.strip() or result.stdout.strip()

    except subprocess.TimeoutExpired:
        return False, f"Rails runner timed out after {timeout}s"
    except FileNotFoundError:
        return False, f"Rails not found. Set RAILS_ROOT env var (current: {RAILS_ROOT})"
    except Exception as e:
        return False, f"Rails runner error: {str(e)}"


def create_subdomain(name: str) -> Tuple[bool, str]:
    """Create a subdomain using direct model access."""
    ruby_code = f'''
subdomain = Subdomain.find_or_create_by!(name: "{name}")
puts JSON.generate({{
  id: subdomain.id,
  name: subdomain.name,
  created_at: subdomain.created_at
}})
'''
    return run_rails_code(ruby_code)


def create_api_namespace(subdomain_name: str, name: str, slug: str, properties: dict) -> Tuple[bool, str]:
    """Create an API namespace using direct model access."""
    properties_ruby = ", ".join([f'"{k}" => "{v}"' for k, v in properties.items()])

    ruby_code = f'''
Apartment::Tenant.switch("{subdomain_name}") do
  namespace = ApiNamespace.find_or_create_by!(slug: "{slug}") do |ns|
    ns.name = "{name}"
    ns.version = 1
    ns.properties = {{ {properties_ruby} }}
    ns.requires_authentication = true
  end
  puts JSON.generate({{
    id: namespace.id,
    name: namespace.name,
    slug: namespace.slug,
    properties: namespace.properties
  }})
end
'''
    return run_rails_code(ruby_code)


def create_cms_page(subdomain_name: str, title: str, slug: str, content: str) -> Tuple[bool, str]:
    """Create a CMS page using direct model access."""
    # Escape content for Ruby string
    escaped_content = content.replace('"', '\\"').replace('\n', '\\n')

    ruby_code = f'''
Apartment::Tenant.switch("{subdomain_name}") do
  site = Comfy::Cms::Site.first
  if site.nil?
    puts JSON.generate({{ error: "No CMS site found" }})
    exit 1
  end

  layout = site.layouts.first || site.layouts.create!(
    identifier: "default",
    content: "{{{{ cms:wysiwyg content }}}}"
  )

  page = site.pages.find_or_create_by!(slug: "{slug}") do |p|
    p.label = "{title}"
    p.layout = layout
  end

  # Update or create fragment
  fragment = page.fragments.find_or_create_by!(identifier: "content")
  fragment.update!(content: "{escaped_content}")

  puts JSON.generate({{
    id: page.id,
    label: page.label,
    slug: page.slug,
    full_path: page.full_path
  }})
end
'''
    return run_rails_code(ruby_code)
