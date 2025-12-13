# Violet Rails Day 0 Guide: From Setup to Release

## Overview

This guide documents the complete Day 0 story for Violet Rails - from downloading and setting up the project, through development and contribution, to releasing changes using Shape Up methodology from Basecamp.

## Table of Contents

1. [VM Setup & Repository Clone](#vm-setup--repository-clone)
2. [Initial Setup & Getting Started](#initial-setup--getting-started)
3. [Development Workflow](#development-workflow)
4. [Contribution Process](#contribution-process)
5. [Code Review & Merging](#code-review--merging)
6. [Release Methodology: Shape Up](#release-methodology-shape-up)
7. [Complete Day 0 Checklist](#complete-day-0-checklist)

---

## VM Setup & Repository Clone

### Prerequisites

Before starting, ensure you have:
- Docker and Docker Compose installed
- Git configured with your SSH keys
- A GitHub account
- At least 8GB RAM available for Docker

### Step 1: Clone the Repository

```bash
# Clone the repository using SSH (recommended)
git clone git@github.com:restarone/violet_rails.git

# Or using HTTPS
git clone https://github.com/restarone/violet_rails.git

# Navigate into the project directory
cd violet_rails
```

### Step 2: Verify Repository Structure

```bash
# Check the repository structure
ls -la

# Verify git remotes
git remote -v

# Check recent commits
git log --oneline -5
```

### Step 3: Create Your Development Branch

```bash
# Create and switch to your feature branch
git checkout -b feature/your-feature-name

# Or for a bug fix
git checkout -b fix/issue-description
```

---

## Initial Setup & Getting Started

### Step 1: Docker Setup

Violet Rails uses Docker for development environment consistency:

```bash
# Build the Docker containers
docker-compose build

# Start all services
docker-compose up

# Attach to the main application container (in separate terminal)
docker attach solutions_app
```

### Step 2: Database Setup

```bash
# Create the database
docker-compose run --rm solutions_app rails db:create

# Run migrations
docker-compose run --rm solutions_app rails db:migrate

# Seed the database with initial data
docker-compose run --rm solutions_app rails db:seed
```

### Step 3: Asset Precompilation

This step needs to be done only once and takes 5-20 minutes:

```bash
docker-compose run --rm solutions_app rails assets:precompile
```

### Step 4: Access the Application

You can access Violet Rails in three ways:

- **`localhost:80`** - With Nginx load balancing
- **`lvh.me:5250`** - For testing subdomains (e.g., `violet.lvh.me:5250`)
- **`localhost:5250`** - Direct Puma server access

### Step 5: Login Credentials

After seeding, you can login with:
- **URL**: `lvh.me:5250/admin` or `localhost:5250/admin`
- **Email**: `violet@rails.com`
- **Password**: `123456`

### Step 6: Environment Configuration

Create `.env.development` file for local environment variables:

```bash
RAILS_ENV=development
DATABASE_HOST=solutions_db
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=password
DATABASE_NAME=r_solutions_development
DATABASE_PORT=5432
APP_HOST=localhost
REDIS_URL=redis://solutions_redis:6379/12
RACK_TIMEOUT_SERVICE_TIMEOUT=200
```

---

## Development Workflow

### Common Development Commands

#### Console Access
```bash
# Rails console
docker-compose run --rm solutions_app rails c

# Attach to running app for debugging
docker attach solutions_app

# Sidekiq logs
docker attach solutions_sidekiq
```

#### Testing
```bash
# Create test database
docker-compose run --rm solutions_test rails db:create
docker-compose run --rm solutions_test rails db:migrate

# Run full test suite
./clean_run_tests.sh

# Run Rails tests only
docker-compose run --rm solutions_test rails test

# Run specific test
docker-compose run --rm solutions_test rails test path/to/test.rb
```

#### Database Operations
```bash
# Create new migration
docker-compose run --rm solutions_app rails generate migration MigrationName

# Rollback migration
docker-compose run --rm solutions_app rails db:rollback

# Reset database
docker-compose run --rm solutions_app rails db:reset
```

### Multi-Tenant Development

Violet Rails uses PostgreSQL schemas for multi-tenancy. When writing rake tasks:

```ruby
desc "Example multi-tenant task"
task :my_task => :environment do 
  subdomains = Subdomain.all_with_public_schema
  subdomains.each do |subdomain|
    Apartment::Tenant.switch subdomain.name do
      # Your code here
    end
  end
end
```

### Email Testing in Development

Access MailCatcher at `http://localhost:1080/` to view sent emails.

---

## Contribution Process

### Step 1: Fork the Repository

1. Go to https://github.com/restarone/violet_rails
2. Click "Fork" in the top right
3. Clone your fork locally
4. Add upstream remote:

```bash
git remote add upstream git@github.com:restarone/violet_rails.git
```

### Step 2: Create Feature Branch

```bash
# Sync with upstream
git fetch upstream
git checkout master
git merge upstream/master

# Create your feature branch
git checkout -b feature/your-feature-name
```

### Step 3: Development Process

1. **Make your changes** following existing code conventions
2. **Write tests** for new functionality
3. **Run the test suite** to ensure nothing breaks:
   ```bash
   ./clean_run_tests.sh
   ```
4. **Test manually** in the browser
5. **Check code coverage** - generated in `coverage/` directory

### Step 4: Commit Your Changes

```bash
# Stage your changes
git add .

# Commit with descriptive message
git commit -m "Add feature description

- Explain what the feature does
- Reference any related issues
- Include any breaking changes"
```

---

## Code Review & Merging

### Step 1: Create Pull Request

1. Push your branch to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. Open a pull request targeting `restarone/violet_rails:master`

### Step 2: PR Requirements

Your PR must include:

#### ✅ Required CI Tests Passing
- All automated tests must pass
- No breaking changes to existing functionality

#### 📝 Description References Issue
- Clear description of what the PR does
- References related issue numbers
- Includes demo video for new features or bug fixes

#### 🧪 Includes Tests
- New code paths must have test coverage
- Tests should exercise the functionality thoroughly

#### ✅ Ready to Merge
- No merge conflicts
- Branch is up-to-date with `master`

### Step 3: Review Process

#### Automated Checks
- **Ruby Tests**: Multiple Ruby/Node.js versions
- **Schema Validation**: Ensures migrations are committed
- **Asset Compilation**: Verifies frontend builds
- **Security Scan**: Brakeman analysis

#### Review App Deployment
Add the `deploy-review-app` label to launch an isolated testing environment:
1. Add label to your PR
2. GitHub Action creates temporary deployment
3. Test your changes in isolation
4. Share link with stakeholders

#### Code Coverage Report
1. Click "Details" on Ruby test job in GitHub Actions
2. Download and open `coverage/index.html`
3. Review coverage for your changes

### Step 4: Merge Process

Once approved:
1. **Review app** is validated by team
2. **Changes** are merged to `rc` branch for staging
3. **Internal testing** on `restarone.solutions`
4. **Final merge** to `master` for production

---

## Release Methodology: Shape Up

Violet Rails uses Basecamp's Shape Up methodology for releases. This approach focuses on shipping meaningful work in fixed-time cycles.

### Core Concepts

#### 🔄 Six-Week Cycles
- **Fixed time, variable scope**
- Teams work uninterruptedly on shaped projects
- Long enough to finish something meaningful
- Short enough to feel deadline pressure

#### 🎯 Shaping the Work
Before betting on a project:

1. **Set Boundaries**: Define the "appetite" (time budget)
2. **Find Elements**: Rough solutions at right level of abstraction
3. **Address Risks**: Identify and eliminate rabbit holes
4. **Write the Pitch**: Document problem, appetite, solution, and risks

#### 🎲 Betting, Not Backlogs
- No traditional backlogs
- **Betting Table**: Stakeholders decide which pitches to bet on
- **Circuit Breaker**: Projects that don't ship in one cycle are canceled by default
- **Clean Slate**: Each cycle starts fresh

#### 🏗️ Building Phase
- **Assign Projects, Not Tasks**: Teams own the entire project
- **Done Means Deployed**: Project isn't done until it's shipped
- **Hill Chart Progress**: Visualize work from unknown to done

### Violet Rails Release Cycle

#### Phase 1: Cool Down (2 weeks)
- Fix bugs and address issues
- Hold **Betting Table** meetings
- Shape projects for next cycle
- Plan upcoming work

#### Phase 2: Development Cycle (6 weeks)
- Teams work on shaped projects
- No interruptions or context switching
- Weekly progress check-ins
- Scope management within timebox

#### Phase 3: Integration & Release
- **Staging Deployment**: Merge to `rc` branch
- **Internal Testing**: Validate on staging environment
- **Production Release**: Merge to `master` branch
- **Monitoring**: Post-release observation

### Release Branch Strategy

```bash
# Development happens on feature branches
git checkout -b feature/new-feature

# Merge to rc for staging
git checkout rc
git merge feature/new-feature
git push origin rc

# After staging validation, merge to master
git checkout master
git merge rc
git push origin master
```

### Automated Deployment Triggers

- **`rc` branch** → Staging environment (`restarone.solutions`)
- **`master` branch** → Production environments (multiple clients)

### Quality Gates

Each release must pass:
1. ✅ All automated tests
2. ✅ Security scans (Brakeman)
3. ✅ Code coverage requirements
4. ✅ Manual QA on staging
5. ✅ Performance benchmarks
6. ✅ Documentation updates

---

## Complete Day 0 Checklist

### ✅ VM & Repository Setup
- [ ] Docker and Docker Compose installed
- [ ] Repository cloned from GitHub
- [ ] Development branch created
- [ ] Upstream remote configured

### ✅ Initial Setup
- [ ] Docker containers built successfully
- [ ] Database created and migrated
- [ ] Database seeded with initial data
- [ ] Assets precompiled
- [ ] Application accessible in browser
- [ ] Environment variables configured
- [ ] Login credentials working

### ✅ Development Environment
- [ ] Rails console accessible
- [ ] Test database created
- [ ] Test suite runs successfully
- [ ] Code coverage reports generating
- [ ] Email testing via MailCatcher
- [ ] Debugging with byebug/pry working

### ✅ Contribution Workflow
- [ ] Fork created on GitHub
- [ ] Git workflow understood
- [ ] Code conventions reviewed
- [ ] Testing requirements understood
- [ ] Commit message format learned

### ✅ Code Review Process
- [ ] PR requirements understood
- [ ] Review app deployment process learned
- [ ] Code coverage review process known
- [ ] Merge process documented

### ✅ Shape Up Methodology
- [ ] Six-week cycle concept understood
- [ ] Shaping process learned
- [ ] Betting table concept grasped
- [ ] Release branch strategy understood
- [ ] Quality gates identified

### 🚀 Ready for Day 1

You're now fully set up to:
- Develop features on Violet Rails
- Contribute to the codebase effectively
- Participate in the release process
- Understand the product development methodology

---

## Quick Reference Commands

```bash
# Start development
docker-compose up && docker attach solutions_app

# Run tests
./clean_run_tests.sh

# Create migration
docker-compose run --rm solutions_app rails g migration Name

# Console access
docker-compose run --rm solutions_app rails c

# Database reset
docker-compose run --rm solutions_app rails db:reset

# Asset precompilation
docker-compose run --rm solutions_app rails assets:precompile

# Git workflow
git checkout -b feature/name
git add .
git commit -m "Description"
git push origin feature-name
```

## Support & Resources

- **Main Documentation**: [README.md](README.md)
- **Development Wiki**: [Getting Started Guide](https://github.com/restarone/violet_rails/wiki/Getting-started-(development-cheatsheet))
- **Shape Up Book**: [Shape Up by Basecamp](https://basecamp.com/shapeup)
- **Issues**: [GitHub Issues](https://github.com/restarone/violet_rails/issues)
- **Discussions**: [GitHub Discussions](https://github.com/restarone/violet_rails/discussions)

---

*This guide represents the complete Day 0 experience for Violet Rails, from initial setup to understanding the full development and release lifecycle.*