"""Pytest configuration for Violet App Agent tests."""

import os
import sys

import pytest


# Add the src directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))


@pytest.fixture(autouse=True)
def set_test_env(monkeypatch):
    """Set test environment variables."""
    monkeypatch.setenv("VIOLET_API_URL", "http://localhost:5250")
    monkeypatch.setenv("VIOLET_API_KEY", "test-key")
    monkeypatch.setenv("APP_HOST", "localhost:5250")
    monkeypatch.setenv("GITHUB_TOKEN", "")


@pytest.fixture
def sample_pet_app_spec():
    """Sample pet adoption app specification."""
    return {
        "subdomain_name": "pet-adoption",
        "app_title": "Pet Adoption Platform",
        "description": "Connect shelters with adopters",
        "namespaces": [
            {
                "name": "Shelter",
                "slug": "shelters",
                "properties": {
                    "name": "String",
                    "address": "String",
                    "phone": "String"
                }
            },
            {
                "name": "Pet",
                "slug": "pets",
                "properties": {
                    "name": "String",
                    "species": "String",
                    "breed": "String",
                    "age": "Integer",
                    "shelter_id": "Integer"
                }
            }
        ],
        "pages": [
            {"type": "index", "namespace": "pets", "title": "Available Pets"},
            {"type": "form", "namespace": "applications", "title": "Apply to Adopt"}
        ]
    }


@pytest.fixture
def sample_blog_spec():
    """Sample blog app specification."""
    return {
        "subdomain_name": "my-blog",
        "app_title": "My Blog",
        "description": "Personal blog with posts and comments",
        "namespaces": [
            {
                "name": "Post",
                "slug": "posts",
                "properties": {
                    "title": "String",
                    "content": "Text",
                    "published": "Boolean"
                }
            },
            {
                "name": "Comment",
                "slug": "comments",
                "properties": {
                    "author": "String",
                    "content": "Text",
                    "post_id": "Integer"
                }
            }
        ],
        "pages": []
    }
