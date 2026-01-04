# Violet Rails Day 0 Guide: From Setup to Release

## Overview

This guide documents the complete Day 0 story for Violet Rails - from downloading and setting up the project, through development and contribution, to releasing changes using Shape Up methodology from Basecamp.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [VM Setup & Repository Clone](#vm-setup--repository-clone)
3. [Initial Setup & Getting Started](#initial-setup--getting-started)
4. [Development Workflow](#development-workflow)
5. [Performance Optimization & Benchmarks](#performance-optimization--benchmarks)
6. [Security Best Practices & Vulnerability Management](#security-best-practices--vulnerability-management)
7. [Contribution Process](#contribution-process)
8. [Code Review & Merging](#code-review--merging)
9. [API Documentation & Integration Examples](#api-documentation--integration-examples)
10. [Release Methodology: Shape Up](#release-methodology-shape-up)
11. [Complete Day 0 Checklist](#complete-day-0-checklist)
12. [Troubleshooting & Common Issues](#troubleshooting--common-issues)
13. [Glossary of Terms & Concepts](#glossary-of-terms--concepts)

---

## Architecture Overview

Violet Rails is a multi-tenant SaaS platform built on Ruby on Rails with a sophisticated architecture designed for scalability and maintainability.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer (Nginx)                   │
├─────────────────────────────────────────────────────────────┤
│                    Application Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Rails     │  │   Sidekiq   │  │   Action Cable      │ │
│  │   App       │  │   Workers   │  │   (WebSockets)      │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ PostgreSQL  │  │    Redis     │  │   File Storage      │ │
│  │ (Multi-tenant)│  │   (Cache)   │  │   (S3/Local)        │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

#### 🏗️ Application Framework
- **Ruby on Rails 6.1.5**: Core web framework
- **Puma 5.6+**: Application server
- **Webpacker 5.0**: JavaScript asset management
- **Stimulus 3.2**: JavaScript framework for interactions

#### 🗄️ Database & Multi-tenancy
- **PostgreSQL 12+**: Primary database with schema-based multi-tenancy
- **Apartment Gem**: Multi-tenant management via PostgreSQL schemas
- **Redis 4.0+**: Caching, session storage, and Sidekiq queue
- **Apartment-Sidekiq**: Multi-tenant background job processing

#### 📦 Key Rails Engines & Gems
- **Comfortable Mexican Sofa**: CMS engine for content management
- **Comfy Blog**: Blogging functionality
- **Simple Discussion**: Forum/community features
- **Devise + Devise Invitable**: Authentication and user management
- **Ahoy Matey**: Analytics and tracking
- **Wicked**: Multi-step form wizards

#### 🎨 Frontend Stack
- **Bootstrap 4**: CSS framework
- **jQuery 3.6**: JavaScript library
- **Chart.js + Chartkick**: Data visualization
- **Trix**: Rich text editor
- **Select2**: Enhanced dropdowns

#### 🔧 Development & Operations
- **Docker & Docker Compose**: Containerization
- **Sidekiq**: Background job processing
- **Brakeman**: Security scanning
- **RSpec**: Testing framework
- **SimpleCov**: Code coverage

### Multi-Tenant Architecture

Violet Rails implements **database-level multi-tenancy** using PostgreSQL schemas:

```
PostgreSQL Database: violet_rails
├── public (shared schema)
├── tenant1_schema
├── tenant2_schema
├── tenant3_schema
└── ...
```

#### Schema Isolation Benefits
- **Data Security**: Complete data isolation between tenants
- **Performance**: Efficient queries with proper indexing
- **Scalability**: Easy to migrate individual tenants to separate databases
- **Backup/Restore**: Granular backup capabilities per tenant

#### Tenant Routing
```ruby
# Subdomain-based tenant identification
# tenant1.example.com → tenant1_schema
# tenant2.example.com → tenant2_schema
```

---

## VM Setup & Repository Clone

### Prerequisites & System Requirements

Before starting, ensure your system meets these requirements:

#### Hardware Requirements
- **RAM**: Minimum 8GB (16GB+ recommended for development)
- **Storage**: At least 10GB free disk space
- **CPU**: 2+ cores (4+ cores recommended)

#### Software Requirements

| Component | Minimum Version | Recommended Version | Notes |
|-----------|----------------|-------------------|-------|
| Docker | 20.10.0+ | 24.0.0+ | Docker Desktop or Docker Engine |
| Docker Compose | 1.29.0+ | 2.20.0+ | V2 format preferred |
| Git | 2.25.0+ | 2.40.0+ | SSH keys configured |
| Ruby | 2.6.6+ | 3.0.0+ | Managed via Docker |
| Node.js | 14.x+ | 18.x+ | Managed via Docker |
| PostgreSQL | 12.0+ | 14.0+ | Managed via Docker |
| Redis | 4.0+ | 6.0+ | Managed via Docker |

#### Platform Compatibility

| Platform | Status | Notes |
|----------|--------|-------|
| macOS 10.15+ | ✅ Fully Supported | Docker Desktop recommended |
| Ubuntu 20.04+ | ✅ Fully Supported | Native Docker installation |
| Windows 10/11 | ✅ Supported | WSL2 with Docker Desktop required |
| CentOS/RHEL 8+ | ⚠️ Partially Supported | May require additional configuration |

#### Development Tools (Optional but Recommended)

```bash
# Verify Docker installation
docker --version
docker-compose --version

# Verify Git configuration
git --version
git config --list | grep user

# Test Docker functionality
docker run hello-world
```

#### Network Requirements

- **Internet Connection**: Required for downloading Docker images and dependencies
- **GitHub Access**: SSH (port 22) or HTTPS (port 443) connectivity
- **Ports**: Ensure ports 80, 5250, 3000, 5432, 6379, 1080 are available

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

Violet Rails uses PostgreSQL schemas for multi-tenancy via the Apartment gem. Each tenant (subdomain) gets its own isolated database schema.

#### Understanding Tenant Switching

```ruby
# Switch to a specific tenant schema
Apartment::Tenant.switch('tenant_name') do
  # All database operations here use tenant_name schema
  User.all          # Queries tenant_name.users table
  Post.create(...)  # Creates in tenant_name.posts table
end

# Switch back to public schema
Apartment::Tenant.switch('public') do
  # Operations on shared data
  Subdomain.all     # Queries public.subdomains table
end
```

#### Writing Multi-Tenant Rake Tasks

```ruby
# lib/tasks/multi_tenant_tasks.rake
namespace :multi_tenant do
  desc "Send welcome emails to all new users across all tenants"
  task send_welcome_emails: :environment do
    # Get all subdomains (tenants)
    subdomains = Subdomain.all_with_public_schema
    
    puts "Processing #{subdomains.count} tenants..."
    
    subdomains.each do |subdomain|
      puts "Processing tenant: #{subdomain.name}"
      
      begin
        Apartment::Tenant.switch(subdomain.name) do
          # Find users who haven't received welcome email
          new_users = User.where(welcome_email_sent: false)
          
          new_users.each do |user|
            UserMailer.welcome_email(user).deliver_later
            user.update(welcome_email_sent: true)
            puts "  Sent welcome email to #{user.email}"
          end
        end
      rescue => e
        puts "  ERROR processing #{subdomain.name}: #{e.message}"
      end
    end
    
    puts "Completed processing all tenants"
  end
end
```

### Email Testing in Development

Access MailCatcher at `http://localhost:1080/` to view sent emails.

---

## Performance Optimization & Benchmarks

Violet Rails is designed for high performance in multi-tenant environments. This section provides benchmarks and optimization guidelines.

### Performance Benchmarks

#### Application Performance Targets

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| Page Load Time | < 500ms | < 1s | > 2s |
| API Response Time | < 200ms | < 500ms | > 1s |
| Database Query Time | < 50ms | < 100ms | > 200ms |
| Background Job Processing | < 5s | < 30s | > 60s |
| Memory Usage per Instance | < 1GB | < 2GB | > 4GB |

### Database Optimization

#### Query Optimization

```ruby
# Bad: N+1 queries
def index
  @posts = Post.all
  # In view: @posts.each { |post| post.user.name } # N+1!
end

# Good: Eager loading
def index
  @posts = Post.includes(:user, :comments)
end
```

#### Database Indexing Strategy

```ruby
# Add indexes for common queries
class AddPerformanceIndexes < ActiveRecord::Migration[6.1]
  def change
    # Composite indexes for multi-column queries
    add_index :posts, [:user_id, :created_at]
    add_index :posts, [:status, :published_at]
    
    # Partial indexes for specific conditions
    add_index :users, :email, where: 'active = true'
    add_index :posts, :title, where: 'published = true'
  end
end
```

### Caching Strategy

#### Fragment Caching

```erb
<!-- app/views/posts/show.html.erb -->
<% cache @post do %>
  <div class="post">
    <h1><%= @post.title %></h1>
    <p><%= @post.content %></p>
    
    <% cache @post.comments do %>
      <div class="comments">
        <%= render @post.comments %>
      </div>
    <% end %>
  </div>
<% end %>
```

---

## Security Best Practices & Vulnerability Management

Violet Rails implements multiple layers of security to protect multi-tenant data and ensure compliance with security standards.

### Authentication & Authorization

#### Secure Authentication Configuration

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  # Use secure password hashing
  config.stretches = Rails.env.test? ? 1 : 12
  
  # Configure session security
  config.timeout_in = 30.minutes
  config.expire_all_after_sign_out = true
  
  # Enable email confirmation
  config.confirm_within = 2.hours
  
  # Configure password requirements
  config.password_length = 12..128
end
```

### Data Protection & Encryption

#### Encrypted Credentials

```ruby
# config/credentials.yml.enc (encrypted)
aws:
  access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  
database:
  password: <%= ENV['DATABASE_PASSWORD'] %>

# Edit credentials:
rails credentials:edit
```

### Input Validation & Sanitization

#### Strong Parameters

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def create
    @post = current_user.posts.new(post_params)
    
    if @post.save
      redirect_to @post, notice: 'Post created successfully'
    else
      render :new
    end
  end
  
  private
  
  def post_params
    params.require(:post).permit(
      :title,
      :content,
      :published,
      tags: []
    ).tap do |whitelisted|
      # Additional validation
      whitelisted[:title] = sanitize_title(whitelisted[:title])
      whitelisted[:content] = sanitize_content(whitelisted[:content])
    end
  end
end
```

### Vulnerability Management

#### Automated Security Scanning

```bash
# Check for vulnerable dependencies
bundle audit --update

# Run security scan
brakeman --quiet --format json --output brakeman-report.json

# Check for outdated gems
bundle outdated
```

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

### Step 4: Merge Process

Once approved:
1. **Review app** is validated by team
2. **Changes** are merged to `rc` branch for staging
3. **Internal testing** on `restarone.solutions`
4. **Final merge** to `master` for production

---

## API Documentation & Integration Examples

Violet Rails provides a comprehensive REST API for building integrations and external applications.

### API Overview

#### Base URL Structure
```
Development: http://localhost:5250/api/v1
Staging: https://restarone.solutions/api/v1
Production: https://your-domain.com/api/v1
```

#### Authentication Methods

##### API Token Authentication
```ruby
# Generate API token for user
user = User.find_by(email: 'user@example.com')
api_token = user.generate_api_token!
```

##### Bearer Token Usage
```bash
# Include token in Authorization header
curl -H "Authorization: Bearer YOUR_API_TOKEN" \
     -H "Content-Type: application/json" \
     https://your-domain.com/api/v1/users
```

### API Endpoints

#### Users API

##### Get Current User
```bash
GET /api/v1/users/me

Response:
{
  "id": 1,
  "email": "user@example.com",
  "name": "John Doe",
  "role": "user",
  "created_at": "2023-01-01T00:00:00Z"
}
```

#### Posts API

##### List Posts
```bash
GET /api/v1/posts?status=published&sort=created_at&order=desc

Response:
{
  "posts": [
    {
      "id": 1,
      "title": "Sample Post",
      "content": "Post content...",
      "status": "published",
      "author": {
        "id": 1,
        "name": "John Doe"
      }
    }
  ]
}
```

### Client Integration Examples

#### JavaScript/Node.js Integration

```javascript
// api-client.js
class VioletAPIClient {
  constructor(baseURL, apiKey) {
    this.baseURL = baseURL;
    this.apiKey = apiKey;
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    const config = {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`,
        ...options.headers
      },
      ...options
    };

    const response = await fetch(url, config);
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'API request failed');
    }

    return response.json();
  }

  async getCurrentUser() {
    return this.request('/api/v1/users/me');
  }

  async getPosts(params = {}) {
    const query = new URLSearchParams(params).toString();
    return this.request(`/api/v1/posts?${query}`);
  }

  async createPost(postData) {
    return this.request('/api/v1/posts', {
      method: 'POST',
      body: JSON.stringify({ post: postData })
    });
  }
}

// Usage example
const client = new VioletAPIClient('https://your-domain.com', 'your-api-key');

async function example() {
  try {
    const user = await client.getCurrentUser();
    console.log('Current user:', user);

    const post = await client.createPost({
      title: 'My New Post',
      content: 'This is content of my post',
      status: 'published'
    });
    console.log('Created post:', post);

  } catch (error) {
    console.error('API Error:', error.message);
  }
}
```

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

### Deployment Environments

#### Development Environment
- **Purpose**: Local development and testing
- **Infrastructure**: Docker Compose on local machine
- **Database**: PostgreSQL container with test data
- **URL**: `localhost:5250`, `lvh.me:5250`

#### Staging Environment
- **Purpose**: Pre-production testing and validation
- **Infrastructure**: AWS EC2 (t3.medium) with single instance
- **Database**: PostgreSQL RDS (db.t3.micro)
- **URL**: `restarone.solutions`

#### Production Environment
- **Purpose**: Live customer-facing application
- **Infrastructure**: AWS EC2 Auto Scaling Group (2+ instances)
- **Database**: PostgreSQL RDS Multi-AZ (db.r5.large)
- **URL**: Multiple client domains

### Quality Gates

Each release must pass:
1. ✅ All automated tests (unit, integration, system)
2. ✅ Security scans (Brakeman, Bundle Audit)
3. ✅ Code coverage requirements (>90% overall, >80% per file)
4. ✅ Manual QA on staging environment
5. ✅ Performance benchmarks (load testing)
6. ✅ Documentation updates
7. ✅ Security review for sensitive changes
8. ✅ Database migration review
9. ✅ Rollback plan verification

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

## Troubleshooting & Common Issues

### Docker & Container Issues

#### Issue: Docker containers fail to start
**Symptoms**: `docker-compose up` fails with port binding errors
**Solutions**:
```bash
# Check what's using the ports
sudo lsof -i :80
sudo lsof -i :5250

# Kill conflicting processes
sudo kill -9 <PID>

# Or change ports in docker-compose.yml
```

#### Issue: Out of memory errors
**Symptoms**: Containers crash with OOM killer messages
**Solutions**:
```bash
# Increase Docker memory allocation in Docker Desktop
# For Linux, add swap space:
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Database Issues

#### Issue: Database connection refused
**Symptoms**: `could not connect to server: Connection refused`
**Solutions**:
```bash
# Check if database container is running
docker-compose ps

# Restart database container
docker-compose restart solutions_db

# Check database logs
docker-compose logs solutions_db

# Manual connection test
docker-compose run --rm solutions_app rails db:migrate:status
```

### Performance Issues

#### Issue: Slow application startup
**Symptoms**: Application takes >5 minutes to start
**Solutions**:
```bash
# Check system resources
docker stats

# Optimize Docker configuration
# Add to docker-compose.yml:
#   deploy:
#     resources:
#       limits:
#         memory: 2G
#       reservations:
#         memory: 1G
```

### Getting Help

If you encounter issues not covered here:

1. **Check Logs**: Always check container logs first
   ```bash
   docker-compose logs solutions_app
   docker-compose logs solutions_db
   docker-compose logs solutions_redis
   ```

2. **Search Issues**: Check [GitHub Issues](https://github.com/restarone/violet_rails/issues)

3. **Community Support**: Use [GitHub Discussions](https://github.com/restarone/violet_rails/discussions)

---

## Glossary of Terms & Concepts

### A
- **Active Record**: Rails ORM for database interactions
- **Action Cable**: Rails framework for WebSocket connections
- **Action Controller**: Rails component handling HTTP requests
- **Action View**: Rails component for rendering views
- **Apartment**: Gem for multi-tenant database management
- **API (Application Programming Interface)**: Interface for programmatic access to application functionality
- **Asset Pipeline**: Rails system for managing CSS, JavaScript, and images
- **Authentication**: Process of verifying user identity
- **Authorization**: Process of determining user permissions

### B
- **Background Jobs**: Asynchronous tasks processed outside request-response cycle
- **Brakeman**: Security scanner for Rails applications
- **Bootstrap**: CSS framework for responsive design
- **Bundler**: Ruby dependency management tool
- **Byebug**: Ruby debugger for development

### C
- **Capistrano**: Deployment automation tool for Rails
- **Capybara**: Testing framework for simulating user interactions
- **CI/CD**: Continuous Integration/Continuous Deployment
- **Comfy Mexican Sofa**: CMS engine for content management
- **Controller**: Rails component that handles requests and responses
- **Coverage**: Measurement of code exercised by tests

### D
- **Database**: Persistent storage for application data
- **Devise**: Authentication solution for Rails
- **Docker**: Containerization platform for consistent environments
- **Docker Compose**: Tool for defining and running multi-container Docker applications

### E
- **Environment**: Configuration context (development, test, staging, production)
- **ERB**: Embedded Ruby templating system
- **Exception**: Error condition that disrupts normal program flow

### F
- **Fixture**: Sample data for testing
- **Form**: HTML interface for user input
- **Frontend**: Client-side part of web application

### G
- **Gem**: Ruby package/library
- **Gemfile**: File listing Ruby dependencies
- **Git**: Version control system
- **GitHub**: Web-based Git repository hosting service

### H
- **Hot Reloading**: Automatic code reloading during development
- **HTML**: HyperText Markup Language for web pages
- **HTTP**: Protocol for web communication

### I
- **Integration Test**: Test verifying interaction between multiple components
- **IRB**: Interactive Ruby shell
- **Issue**: Bug report or feature request

### J
- **JavaScript**: Programming language for web interactivity
- **jQuery**: JavaScript library for DOM manipulation
- **JSON**: Data interchange format

### K
- **Key**: Secret value for encryption or authentication

### L
- **Load Balancer**: Distributes incoming traffic across multiple servers
- **Logging**: Recording application events for debugging and monitoring

### M
- **Migration**: Rails mechanism for database schema changes
- **Model**: Rails component representing data and business logic
- **Multi-tenancy**: Architecture where single application serves multiple clients
- **MVC**: Model-View-Controller architectural pattern

### N
- **N+1 Query**: Performance issue where additional queries are executed in loops
- **Namespace**: Logical grouping of related code

### O
- **ORM (Object-Relational Mapping)**: Technique for converting objects to database records
- **OAuth**: Authentication protocol for third-party access

### P
- **Puma**: Ruby web server
- **PostgreSQL**: Open-source relational database
- **Production**: Live environment for end users
- **Pull Request**: Proposed changes to a code repository

### Q
- **Query**: Request for data from database
- **Queue**: Data structure for managing background jobs

### R
- **Rails**: Ruby on Rails web framework
- **Rake**: Ruby build tool
- **Redis**: In-memory data structure store
- **Repository**: Storage location for code
- **RSpec**: Testing framework for Ruby (alternative to Minitest)
- **Route**: URL pattern mapping to controller actions

### S
- **Schema**: Database structure definition
- **Security**: Protection against threats and vulnerabilities
- **Sidekiq**: Background job processing framework
- **SimpleCov**: Code coverage tool for Ruby
- **Staging**: Pre-production environment for testing
- **Strong Parameters**: Rails security feature for mass assignment protection
- **System Test**: End-to-end test simulating real user scenarios

### T
- **Tenant**: Isolated data set in multi-tenant architecture
- **Test**: Automated verification of code behavior
- **TDD (Test-Driven Development)**: Development approach where tests are written before code
- **Turbo**: Rails framework for fast page updates
- **Two-Factor Authentication (2FA)**: Additional security layer requiring two forms of verification

### U
- **Unit Test**: Test verifying individual component behavior
- **URL**: Uniform Resource Locator for web addresses
- **User**: Person who interacts with the application

### V
- **Validation**: Rules ensuring data integrity
- **View**: Rails component for rendering user interface
- **Version Control**: System for tracking code changes

### W
- **Webpack**: JavaScript module bundler
- **WebSocket**: Protocol for real-time communication
- **WYSIWYG**: "What You See Is What You Get" editor

### X
- **XSS (Cross-Site Scripting)**: Security vulnerability allowing script injection

### Y
- **YAML**: Human-readable data serialization format
- **Yarn**: JavaScript package manager

### Z
- **Zero-Downtime Deployment**: Deployment strategy without service interruption

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