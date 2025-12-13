# Violet Rails - Agent Guidelines

## Build/Lint/Test Commands

### Testing
- **Full test suite**: `./clean_run_tests.sh` (runs in parallel, no TTY support)
- **Single test**: `docker-compose run --rm solutions_test rails test path/to/test.rb`
- **Single test method**: `docker-compose run --rm solutions_test rails test path/to/test.rb::test_method_name`
- **Quick test run**: `./run_tests.sh` (faster, no parallel)
- **Test database setup**: `docker-compose run --rm solutions_test rails db:test:prepare`

### Assets
- **Precompile**: `docker-compose run --rm solutions_app rails assets:precompile`
- **Clean assets**: `docker-compose run --rm solutions_app rails assets:clobber`

### Database
- **Migrate**: `docker-compose run --rm solutions_app rails db:migrate`
- **Rollback**: `docker-compose run --rm solutions_app rails db:rollback`
- **Console**: `docker-compose run --rm solutions_app rails c`

## Code Style Guidelines

### Ruby/Rails
- **Naming**: PascalCase for classes, snake_case for methods/variables
- **Models**: Inherit from `ApplicationRecord`, use constants for private attributes
- **Controllers**: Inherit from `ApplicationController`, use `before_action` callbacks
- **Tests**: Use Minitest, fixtures in `test/fixtures/`, descriptive test names
- **Multi-tenant**: Always use `Apartment::Tenant.switch(tenant_name)` for tenant-specific operations

### JavaScript
- **Imports**: Use ES6 `import/export` syntax, require statements for legacy code
- **jQuery**: Available globally as `$` and `jQuery`
- **Bootstrap**: Required globally, use Bootstrap 4 classes
- **Stimulus**: Import controllers from `controllers` directory

### Error Handling
- **Controllers**: Use Rails rescue_from for common exceptions
- **Models**: Use validations and custom error messages
- **Background Jobs**: Handle exceptions with proper logging
- **API**: Return consistent JSON error format with status codes

### File Organization
- **Models**: `app/models/` with concerns in `app/models/concerns/`
- **Controllers**: `app/controllers/` with namespacing for admin/api
- **Views**: Follow Rails conventions, partials prefixed with `_`
- **Tests**: Mirror app structure in `test/` directory
- **JavaScript**: `app/javascript/` with packs in `app/javascript/packs/`

### Security
- **Authentication**: Use Devise, include two-factor authentication
- **Authorization**: Role-based access control with tenant isolation
- **Inputs**: Use strong parameters, sanitize user input
- **API**: Token-based authentication, rate limiting

### Multi-Tenancy
- **Tenant switching**: Always wrap tenant-specific code in `Apartment::Tenant.switch`
- **Shared data**: Use `public` schema for cross-tenant data
- **Migrations**: Consider tenant impact, use safe migration practices
- **Background jobs**: Include tenant context in job parameters