# Violet Rails: Good First Issues & Contribution Guide

## 🎯 5 Good First Issues for New Contributors

Based on my analysis of the Violet Rails codebase, here are 5 well-scoped, low-risk issues perfect for new contributors:

### 1. **Remove TODO Comments and Clean Up Code** (Easy)
**Files & Locations:**
- `app/graphql/types/mutation_type.rb:3` - Remove test field
- `config/initializers/sidekiq.rb:3` - Implement Current attribute persistence
- `app/services/webhook/verification_method/custom.rb:12` - Fix validation return format
- `app/graphql/r_solutions_schema.rb:19` - Implement resolve_type method

**Why it's good for beginners:**
- Clear, isolated changes
- No complex business logic
- Immediate impact on code quality
- Easy to test and validate

**Implementation approach:**
```ruby
# Example: Remove test field from mutation_type.rb
# field :test_field, String, null: true # <- DELETE THIS LINE
```

### 2. **Add Missing Test Coverage** (Easy to Medium)
**Files & Locations:**
- `test/models/sales_asset_test.rb` - Only placeholder test exists
- `test/models/message_test.rb` - Only placeholder test exists
- `test/models/message_thread_test.rb` - Only placeholder test exists
- `test/models/mailbox_test.rb` - Only placeholder test exists

**Why it's good for beginners:**
- Well-defined models to test
- Clear validation rules to cover
- Rails testing patterns are well-documented
- Immediate impact on code coverage metrics

**Example test structure:**
```ruby
# test/models/sales_asset_test.rb
require "test_helper"

class SalesAssetTest < ActiveSupport::TestCase
  test "should be valid with all attributes" do
    sales_asset = SalesAsset.new(
      name: "Test Asset",
      width: 100,
      height: 100,
      html: "<div>Test</div>"
    )
    assert sales_asset.valid?
  end

  test "should validate presence of name" do
    sales_asset = SalesAsset.new
    assert_not sales_asset.valid?
    assert_includes sales_asset.errors[:name], "can't be blank"
  end
end
```

### 3. **Fix Broad Exception Handling** (Easy to Medium)
**Files & Locations:**
- `app/models/api_action.rb:113,128,142` - Replace generic rescues
- `app/models/api_namespace.rb:219,358` - Replace generic rescues
- `app/models/ahoy/event.rb:110` - Replace generic rescue

**Why it's good for beginners:**
- Clear pattern to follow
- Improves error handling and debugging
- Low risk of breaking existing functionality
- Teaches Rails exception handling best practices

**Before:**
```ruby
rescue => e
  Rails.logger.error "Something went wrong: #{e.message}"
end
```

**After:**
```ruby
rescue ActiveRecord::RecordNotFound => e
  Rails.logger.error "Record not found: #{e.message}"
rescue StandardError => e
  Rails.logger.error "Unexpected error: #{e.message}"
end
```

### 4. **Optimize Database Queries** (Easy)
**Files & Locations:**
- `app/models/subdomain.rb:238-239` - Replace `.all.each` with `find_each`
- `app/models/api_namespace.rb:149` - Replace `.each` with `find_each`

**Why it's good for beginners:**
- Clear performance improvement
- Simple pattern replacement
- Teaches Rails memory management
- Easy to measure impact

**Before:**
```ruby
Subdomain.all.each do |subdomain|
  # process subdomain
end
```

**After:**
```ruby
Subdomain.find_each do |subdomain|
  # process subdomain
end
```

### 5. **Remove Deprecated Ember Integration Tests** (Easy)
**Files & Locations:**
- `test/integration/ember/ember_js_renderer_test.rb:6,16` - Remove skipped tests

**Why it's good for beginners:**
- Clear removal of dead code
- No risk of breaking functionality
- Improves test suite performance
- Simple file deletion/commenting

---

## ⚠️ Critical Footguns to Avoid

### 1. **Multi-Tenancy Complexity**
**Footgun:** Violet Rails uses PostgreSQL schemas for multi-tenancy via the `apartment` gem.

**What can go wrong:**
- Running migrations in wrong schema
- Data leakage between tenants
- Cross-tenant data access

**How to avoid:**
```ruby
# ALWAYS wrap tenant-specific operations
Apartment::Tenant.switch(subdomain.name) do
  # Your code here
end

# NEVER access data directly without switching
User.all # BAD - accesses public schema
```

### 2. **Docker Development Environment**
**Footgun:** Complex Docker setup with multiple services.

**What can go wrong:**
- Database connection issues
- Asset compilation failures
- Container networking problems

**How to avoid:**
```bash
# Always use the full docker-compose commands
docker-compose run --rm solutions_app rails db:migrate
# NOT: rails db:migrate (runs outside container)

# Attach to correct container
docker attach solutions_app
# NOT: running commands locally
```

### 3. **Asset Pipeline Complexity**
**Footgun:** Violet Rails uses Webpacker with Ember.js frontend.

**What can go wrong:**
- Asset compilation failures
- JavaScript errors breaking admin UI
- CSS not updating

**How to avoid:**
```bash
# Always precompile after major changes
docker-compose run --rm solutions_app rails assets:precompile

# Check both Rails and Ember builds
docker-compose run --rm solutions_app rails assets:clobber
docker-compose run --rm solutions_app rails assets:precompile
```

### 4. **Sidekiq Background Jobs**
**Footgun:** Background job processing with complex dependencies.

**What can go wrong:**
- Jobs failing silently
- Memory leaks in long-running jobs
- Incorrect job retry logic

**How to avoid:**
```ruby
# Always handle specific exceptions
class MyJob < ApplicationJob
  retry_on StandardError, wait: :exponentially_longer

  def perform(*args)
    # Your code here
  rescue ActiveRecord::RecordNotFound => e
    # Handle specific case
  end
end
```

### 5. **GraphQL Schema Evolution**
**Footgun:** GraphQL API with custom types and mutations.

**What can go wrong:**
- Breaking changes to existing queries
- Type conflicts
- N+1 query problems

**How to avoid:**
```ruby
# Always test GraphQL changes
# Use GraphQL Playground for testing
# Check for N+1 queries with bullet gem
```

---

## 🚀 Getting Your Contribution Merged

### Step 1: Setup Development Environment
```bash
# 1. Clone and setup
git clone git@github.com:restarone/violet_rails.git
cd violet_rails

# 2. Docker setup (takes 15-20 minutes)
docker-compose build

# 3. Database setup
docker-compose run --rm solutions_app rails db:create db:migrate db:seed

# 4. Asset compilation (5-20 minutes)
docker-compose run --rm solutions_app rails assets:precompile

# 5. Start development
docker-compose up
# In new terminal: docker attach solutions_app
```

### Step 2: Create Your Branch
```bash
git checkout -b fix/issue-description
# or
git checkout -b feature/feature-name
```

### Step 3: Make Your Changes
1. **Follow existing code patterns** - Look at similar files for conventions
2. **Write tests** - All new code needs test coverage
3. **Run test suite** - Ensure nothing breaks:
   ```bash
   ./clean_run_tests.sh
   ```

### Step 4: Quality Checks
```bash
# 1. Run full test suite
./clean_run_tests.sh

# 2. Check code coverage (generated in coverage/ directory)
open coverage/index.html

# 3. Test manually in browser
# Access at http://lvh.me:5250/admin
# Login: violet@rails.com / 123456

# 4. Check for security issues
docker-compose run --rm solutions_app bundle exec brakeman
```

### Step 5: Commit and Push
```bash
git add .
git commit -m "Fix: Replace broad exception handling with specific exceptions

- Replace rescue => e with specific exception types
- Improve error logging and debugging
- Addresses code quality issues in api_action.rb and api_namespace.rb

Closes #[issue-number]"
```

### Step 6: Create Pull Request
1. Push to your fork: `git push origin fix/issue-description`
2. Open PR targeting `restarone/violet_rails:master`
3. **Add `deploy-review-app` label** to launch testing environment
4. Fill out PR template completely
5. Include demo video if applicable

### Step 7: Review Process
1. **Automated checks must pass:**
   - Ruby tests (multiple versions)
   - Node.js tests
   - Security scan (Brakeman)
   - Asset compilation

2. **Manual review:**
   - Code quality and conventions
   - Test coverage
   - Documentation updates

3. **Review app testing:**
   - Your PR will be deployed to isolated environment
   - Test your changes thoroughly
   - Share link with reviewers

### Step 8: Merge Process
1. **PR approved** → Merged to `rc` branch
2. **Staging deployment** → Internal testing on `restarone.solutions`
3. **Production release** → Merged to `master` branch

---

## 📋 Pre-Merge Checklist

### Code Quality
- [ ] Follows existing code conventions
- [ ] No RuboCop offenses
- [ ] No Brakeman security warnings
- [ ] Tests cover new functionality
- [ ] Documentation updated if needed

### Testing
- [ ] All tests pass locally: `./clean_run_tests.sh`
- [ ] Code coverage maintained or improved
- [ ] Manual testing completed in browser
- [ ] Edge cases considered and tested

### Multi-Tenancy
- [ ] Tenant isolation maintained
- [ ] No cross-tenant data access
- [ ] Proper schema switching used

### Performance
- [ ] No N+1 queries introduced
- [ ] Database queries optimized
- [ ] Memory usage considered

### Security
- [ ] No sensitive data exposed
- [ ] Proper authorization checks
- [ ] Input validation present
- [ ] SQL injection prevention

---

## 🎯 Quick Wins for First-Time Contributors

### The Easiest First Issue
**Remove TODO comment from GraphQL mutation type:**
1. Open `app/graphql/types/mutation_type.rb`
2. Delete line 3: `field :test_field, String, null: true`
3. Run tests: `./clean_run_tests.sh`
4. Commit and PR

### Why This is Perfect:
- 1 line change
- No complex logic
- Tests will immediately validate
- Teaches the full contribution workflow
- Builds confidence for larger changes

---

## 📞 Getting Help

### Resources
- **Development Wiki**: https://github.com/restarone/violet_rails/wiki/Getting-started-(development-cheatsheet)
- **Day 0 Guide**: `DAY_0_GUIDE.md` in repository
- **Contributing Guide**: `CONTRIBUTING.md` in repository

### Common Issues
1. **Docker build fails** → Check Docker Desktop is running
2. **Database connection errors** → Verify `.env.development` file
3. **Asset compilation fails** → Run `rails assets:clobber` then retry
4. **Tests fail** → Check if database is properly migrated

### Community
- **GitHub Issues**: Report bugs and request features
- **GitHub Discussions**: Ask questions and share ideas
- **Review Apps**: Test changes in isolated environments

---

## 🏆 Success Metrics

Your contribution is successful when:
1. ✅ All automated tests pass
2. ✅ Code coverage is maintained
3. ✅ Review app works correctly
4. ✅ PR is merged to `rc` branch
5. ✅ Changes deploy to staging successfully
6. ✅ Final merge to `master` branch

Welcome to Violet Rails open source! 🎉