"""GitHub integration tools for deployment."""

import os
from typing import Literal

from langchain_core.tools import tool

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")


@tool
def trigger_deployment(
    subdomain: str,
    target: Literal["local", "heroku", "ec2", "review-app"] = "local",
    repo: str = "",
    branch: str = "main",
) -> str:
    """
    Trigger deployment of a subdomain via GitHub Actions.

    For now, this provides deployment instructions. Future versions
    will integrate directly with the GitHub API.

    Args:
        subdomain: The subdomain to deploy
        target: Deployment target:
            - "local": Already deployed to local development
            - "heroku": Deploy to Heroku
            - "ec2": Deploy to AWS EC2 via Capistrano
            - "review-app": Create a GitHub review app
        repo: GitHub repository (owner/repo format). Required for non-local.
        branch: Branch to deploy from

    Returns:
        Deployment status or instructions
    """
    if target == "local":
        return f"""✓ Your app is running locally!

**Local URLs:**
- App: http://{subdomain}.localhost:5250
- Admin: http://{subdomain}.localhost:5250/admin

No additional deployment needed for local development.
"""

    if not repo:
        return "Error: GitHub repository (owner/repo) is required for cloud deployment."

    if not GITHUB_TOKEN:
        return """Error: GitHub token not configured.

To enable deployment, set the GITHUB_TOKEN environment variable
with a token that has workflow permissions.
"""

    # For MVP, provide manual instructions
    # TODO: Implement GitHub API integration with Octokit
    if target == "heroku":
        return f"""## Deploy to Heroku

Your app configuration is ready. To deploy:

1. Push your changes to the `{branch}` branch:
   ```bash
   git push origin {branch}
   ```

2. The GitHub Action at `.github/workflows/heroku-deploy.yml` will:
   - Build the application
   - Run database migrations
   - Deploy to Heroku

**Monitor deployment:**
https://github.com/{repo}/actions

**After deployment:**
Your app will be available at your Heroku app URL.
"""
    elif target == "ec2":
        return f"""## Deploy to AWS EC2

Your app configuration is ready. To deploy:

1. Push your changes to the `{branch}` branch:
   ```bash
   git push origin {branch}
   ```

2. The GitHub Action at `.github/workflows/deploy.yml` will:
   - Connect to your EC2 instance via SSH
   - Run Capistrano deployment
   - Restart application services

**Monitor deployment:**
https://github.com/{repo}/actions

**Note:** Ensure your EC2 instance and deployment keys are configured.
"""
    elif target == "review-app":
        return f"""## Create Review App

To create a review app for testing:

1. Create a pull request with your changes
2. Add the `deploy-review-app` label to the PR
3. GitHub Actions will automatically:
   - Create an isolated review environment
   - Deploy your changes
   - Comment on the PR with the review app URL

**Monitor:**
https://github.com/{repo}/pulls

The review app will be automatically destroyed when the PR is closed.
"""
    else:
        return f"Error: Unknown deployment target '{target}'."
