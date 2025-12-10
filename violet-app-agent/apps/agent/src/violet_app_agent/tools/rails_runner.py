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
# DISABLE_SPRING=1 prevents fork() issues on macOS (INC-20251208-003)
RAILS_ENV = {
    "DISABLE_SPRING": "1",
    "OBJC_DISABLE_INITIALIZE_FORK_SAFETY": "YES",
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


def check_db_health() -> Tuple[bool, str]:
    """
    Check database connectivity at agent startup.
    Call this before processing requests to fail fast if DB is unavailable.

    Returns:
        Tuple of (healthy: bool, message: str with JSON status)
    """
    health_check_code = '''
begin
  ActiveRecord::Base.connection.execute("SELECT 1")
  subdomain_count = Subdomain.count
  puts JSON.generate({
    status: "healthy",
    database: ActiveRecord::Base.connection.current_database,
    subdomain_count: subdomain_count,
    rails_env: Rails.env
  })
rescue => e
  puts JSON.generate({
    status: "unhealthy",
    error: e.message,
    error_class: e.class.name
  })
  exit 1
end
'''
    success, output = run_rails_code(health_check_code)
    if success:
        return True, output
    else:
        return False, f"DB Health Check Failed: {output}"


def create_subdomain(name: str) -> Tuple[bool, str]:
    """Create a subdomain using direct model access with verification."""
    # Step 1: Create the subdomain
    create_code = f'''
subdomain = Subdomain.find_or_create_by!(name: "{name}")
puts subdomain.id
'''
    success, output = run_rails_code(create_code)
    if not success:
        return False, f"Failed to create subdomain: {output}"

    subdomain_id = output.strip()

    # Step 2: Verify it exists (separate query to confirm persistence)
    verify_code = f'''
subdomain = Subdomain.find_by(id: {subdomain_id})
if subdomain.nil?
  puts JSON.generate({{ error: "VERIFICATION FAILED: Subdomain {subdomain_id} not found after create" }})
  exit 1
end
puts JSON.generate({{
  id: subdomain.id,
  name: subdomain.name,
  created_at: subdomain.created_at,
  verified: true
}})
'''
    return run_rails_code(verify_code)


def create_api_namespace(subdomain_name: str, name: str, slug: str, properties: dict) -> Tuple[bool, str]:
    """Create an API namespace using direct model access with verification."""
    properties_ruby = ", ".join([f'"{k}" => "{v}"' for k, v in properties.items()])

    # Step 1: Create the namespace
    create_code = f'''
Apartment::Tenant.switch("{subdomain_name}") do
  namespace = ApiNamespace.find_or_create_by!(slug: "{slug}") do |ns|
    ns.name = "{name}"
    ns.version = 1
    ns.properties = {{ {properties_ruby} }}
    ns.requires_authentication = true
  end
  puts namespace.id
end
'''
    success, output = run_rails_code(create_code)
    if not success:
        return False, f"Failed to create namespace: {output}"

    namespace_id = output.strip()

    # Step 2: Verify it exists (separate query to confirm persistence)
    verify_code = f'''
Apartment::Tenant.switch("{subdomain_name}") do
  namespace = ApiNamespace.find_by(id: {namespace_id})
  if namespace.nil?
    puts JSON.generate({{ error: "VERIFICATION FAILED: Namespace {namespace_id} not found after create" }})
    exit 1
  end
  puts JSON.generate({{
    id: namespace.id,
    name: namespace.name,
    slug: namespace.slug,
    properties: namespace.properties,
    verified: true
  }})
end
'''
    return run_rails_code(verify_code)


def create_cms_page(subdomain_name: str, title: str, slug: str, content: str) -> Tuple[bool, str]:
    """Create a CMS page using direct model access with verification."""
    # Escape content for Ruby string
    escaped_content = content.replace('"', '\\"').replace('\n', '\\n')

    # Step 1: Create the page
    create_code = f'''
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

  puts page.id
end
'''
    success, output = run_rails_code(create_code)
    if not success:
        return False, f"Failed to create page: {output}"

    page_id = output.strip()

    # Step 2: Verify it exists (separate query to confirm persistence)
    verify_code = f'''
Apartment::Tenant.switch("{subdomain_name}") do
  page = Comfy::Cms::Page.find_by(id: {page_id})
  if page.nil?
    puts JSON.generate({{ error: "VERIFICATION FAILED: Page {page_id} not found after create" }})
    exit 1
  end
  puts JSON.generate({{
    id: page.id,
    label: page.label,
    slug: page.slug,
    full_path: page.full_path,
    verified: true
  }})
end
'''
    return run_rails_code(verify_code)
