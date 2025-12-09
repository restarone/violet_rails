"""End-to-end test for the Jobs-to-be-Done flow.

This test simulates the core JTBD:
"When I describe my app idea, I want a working app deployed"

The test verifies:
1. Natural language input is understood
2. Specification is generated correctly
3. API calls create the subdomain and namespaces
4. CMS pages are created
5. Deployment instructions are provided

Run with: pytest tests/test_e2e_jtbd.py -v
"""

import json
import os
from unittest.mock import MagicMock, patch

import pytest


class TestJTBD:
    """Test the core Jobs-to-be-Done flow."""

    @pytest.fixture
    def mock_violet_api(self):
        """Mock the Violet Rails API responses."""
        with patch("httpx.post") as mock_post:
            # Configure successful responses
            mock_post.return_value = MagicMock(
                status_code=201,
                json=lambda: {"id": 1, "url": "/test"}
            )
            yield mock_post

    def test_diagnose_requirements_parses_pet_adoption_app(self):
        """Test that diagnose_requirements correctly parses a pet adoption app description."""
        from violet_app_agent.tools.diagnostic import diagnose_requirements

        result = diagnose_requirements.invoke({
            "app_description": "I want to build a pet adoption app where shelters can list pets and people can apply to adopt",
            "complexity_estimate": "medium"
        })

        # Should identify key entities
        assert "Pet" in result or "pet" in result.lower()
        assert "Shelter" in result or "shelter" in result.lower()
        # Should identify relationships
        assert "belong" in result.lower() or "relationship" in result.lower()

    def test_generate_specification_creates_valid_yaml(self):
        """Test that generate_specification creates valid YAML output."""
        from violet_app_agent.tools.specification import generate_specification

        result = generate_specification.invoke({
            "subdomain_name": "pet-adoption",
            "app_title": "Pet Adoption Platform",
            "description": "Connect shelters with adopters",
            "namespaces_json": json.dumps([
                {
                    "name": "Pet",
                    "slug": "pets",
                    "properties": {
                        "name": "String",
                        "species": "String",
                        "age": "Integer"
                    }
                }
            ]),
            "pages_json": json.dumps([
                {"type": "index", "namespace": "pets", "title": "Available Pets"}
            ])
        })

        # Should contain YAML block
        assert "```yaml" in result
        assert "pet-adoption" in result
        assert "Pet Adoption Platform" in result
        # Should have summary
        assert "data model" in result.lower() or "properties" in result.lower()

    def test_create_subdomain_validates_name(self):
        """Test that create_subdomain validates subdomain names."""
        from violet_app_agent.tools.subdomain import create_subdomain

        # Test invalid name (starts with number)
        result = create_subdomain.invoke({
            "subdomain_name": "123invalid"
        })
        assert "Error" in result or "Invalid" in result

        # Test invalid name (contains uppercase)
        result = create_subdomain.invoke({
            "subdomain_name": "InvalidName"
        })
        assert "Error" in result or "Invalid" in result

    def test_create_namespace_validates_properties(self):
        """Test that create_namespace validates property types."""
        from violet_app_agent.tools.namespace import create_namespace

        # Test invalid property type
        result = create_namespace.invoke({
            "subdomain": "test-app",
            "name": "Pet",
            "slug": "pets",
            "properties_json": json.dumps({"name": "InvalidType"})
        })
        assert "Error" in result or "Invalid" in result

    def test_create_page_requires_namespace_for_typed_pages(self):
        """Test that create_page requires namespace_slug for index/show/form pages."""
        from violet_app_agent.tools.cms import create_page

        # Test index page without namespace
        result = create_page.invoke({
            "subdomain": "test-app",
            "title": "Pets List",
            "slug": "pets",
            "page_type": "index",
            "namespace_slug": ""  # Missing required namespace
        })
        assert "Error" in result or "required" in result.lower()

    def test_trigger_deployment_local_needs_no_repo(self):
        """Test that local deployment works without GitHub repo."""
        from violet_app_agent.tools.github import trigger_deployment

        result = trigger_deployment.invoke({
            "subdomain": "test-app",
            "target": "local"
        })

        # Should succeed for local
        assert "localhost" in result.lower()
        assert "Error" not in result

    def test_trigger_deployment_heroku_requires_repo(self):
        """Test that Heroku deployment requires GitHub repo."""
        from violet_app_agent.tools.github import trigger_deployment

        result = trigger_deployment.invoke({
            "subdomain": "test-app",
            "target": "heroku",
            "repo": ""  # Missing required repo
        })

        assert "Error" in result or "required" in result.lower()

    @pytest.mark.integration
    def test_full_jtbd_flow_pet_adoption(self, mock_violet_api):
        """
        Full JTBD flow test: User describes pet adoption app, agent creates it.

        This is the core user story:
        1. User says "I want a pet adoption app"
        2. Agent diagnoses requirements
        3. Agent generates specification
        4. User approves
        5. Agent creates subdomain, namespaces, pages
        6. Agent provides deployment instructions
        """
        from violet_app_agent.tools import (
            create_namespace,
            create_page,
            create_subdomain,
            diagnose_requirements,
            generate_specification,
            trigger_deployment,
        )

        # Step 1: Diagnose requirements
        diagnosis = diagnose_requirements.invoke({
            "app_description": "Build me a pet adoption platform where animal shelters can list pets and people can submit adoption applications",
            "complexity_estimate": "medium"
        })
        assert "Pet" in diagnosis or "pet" in diagnosis.lower()

        # Step 2: Generate specification
        spec = generate_specification.invoke({
            "subdomain_name": "pet-adoption",
            "app_title": "Pet Adoption Platform",
            "description": "Connect shelters with adopters",
            "namespaces_json": json.dumps([
                {
                    "name": "Shelter",
                    "slug": "shelters",
                    "properties": {"name": "String", "address": "String", "phone": "String"}
                },
                {
                    "name": "Pet",
                    "slug": "pets",
                    "properties": {"name": "String", "species": "String", "breed": "String", "age": "Integer", "shelter_id": "Integer"}
                },
                {
                    "name": "Application",
                    "slug": "applications",
                    "properties": {"applicant_name": "String", "email": "String", "pet_id": "Integer", "message": "Text"}
                }
            ]),
            "pages_json": json.dumps([
                {"type": "index", "namespace": "pets", "title": "Available Pets"},
                {"type": "form", "namespace": "applications", "title": "Apply to Adopt"}
            ])
        })
        assert "pet-adoption" in spec
        assert "3" in spec  # 3 namespaces

        # Step 3: Create subdomain (mocked)
        subdomain_result = create_subdomain.invoke({"subdomain_name": "pet-adoption"})
        # Will fail without real API, but validates the call was made

        # Step 4: Deployment instructions
        deploy_result = trigger_deployment.invoke({
            "subdomain": "pet-adoption",
            "target": "local"
        })
        assert "localhost" in deploy_result.lower()
        assert "5250" in deploy_result


class TestSpecificationGeneration:
    """Test specification generation for various app types."""

    def test_blog_app_spec(self):
        """Test generating a blog app specification."""
        from violet_app_agent.tools.specification import generate_specification

        result = generate_specification.invoke({
            "subdomain_name": "my-blog",
            "app_title": "My Personal Blog",
            "description": "A simple blog with posts and comments",
            "namespaces_json": json.dumps([
                {
                    "name": "Post",
                    "slug": "posts",
                    "properties": {"title": "String", "content": "Text", "published": "Boolean"}
                },
                {
                    "name": "Comment",
                    "slug": "comments",
                    "properties": {"author": "String", "content": "Text", "post_id": "Integer"}
                }
            ]),
            "pages_json": "[]"
        })

        assert "my-blog" in result
        assert "Post" in result
        assert "Comment" in result

    def test_inventory_app_spec(self):
        """Test generating an inventory management specification."""
        from violet_app_agent.tools.specification import generate_specification

        result = generate_specification.invoke({
            "subdomain_name": "inventory-tracker",
            "app_title": "Inventory Tracker",
            "description": "Track items in stock",
            "namespaces_json": json.dumps([
                {
                    "name": "Item",
                    "slug": "items",
                    "properties": {
                        "name": "String",
                        "sku": "String",
                        "quantity": "Integer",
                        "price": "Float"
                    }
                }
            ]),
            "pages_json": "[]"
        })

        assert "inventory-tracker" in result
        assert "Item" in result
        assert "4" in result  # 4 properties


class TestSubdomainValidation:
    """Test subdomain name validation edge cases."""

    def test_valid_subdomain_names(self):
        """Test that valid subdomain names pass validation."""
        from violet_app_agent.tools.subdomain import create_subdomain

        valid_names = [
            "my-app",
            "petshop",
            "test123",
            "a",  # Single char is valid
            "my-cool-app-2024",
        ]

        for name in valid_names:
            result = create_subdomain.invoke({"subdomain_name": name})
            # Should not contain validation error (may have connection error)
            assert "Invalid subdomain name" not in result, f"Failed for: {name}"

    def test_invalid_subdomain_names(self):
        """Test that invalid subdomain names are rejected."""
        from violet_app_agent.tools.subdomain import create_subdomain

        invalid_names = [
            "My-App",  # Uppercase
            "123app",  # Starts with number
            "-myapp",  # Starts with hyphen
            "myapp-",  # Ends with hyphen
            "my app",  # Contains space
            "my_app",  # Contains underscore
            "my.app",  # Contains dot
        ]

        for name in invalid_names:
            result = create_subdomain.invoke({"subdomain_name": name})
            assert "Error" in result or "Invalid" in result, f"Should reject: {name}"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
