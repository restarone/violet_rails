# DSA Directory Setup Guide

## Overview
This guide walks through setting up the DSA (Data Structures & Algorithms) Directory using Violet Rails. We're building an educational platform to track and teach 30 essential algorithms across 7 learning phases.

## Prerequisites Completed ✅
- Docker containers built
- Database created, migrated, and seeded
- Asset precompilation in progress
- Import rake task created (`lib/tasks/import_dsa.rake`)
- Seed data prepared (`dsa-seed-data.rb`)

## Next Steps

### Step 1: Verify Violet Rails is Running
After asset precompilation completes:

1. Access the application: http://localhost:5250/admin
2. Login with default credentials:
   - Email: `violet@rails.com`
   - Password: `123456`

### Step 2: Create the DSA Subdomain

**Option A: Via Signup Wizard (Recommended)**
1. Navigate to http://localhost:5250/signup_wizard
2. Fill in the form:
   - **Subdomain Name**: `dsa`
   - **Email**: your email address
   - **Password**: choose a secure password
3. Check the database or admin panel to approve the subdomain request
4. Log in to the new subdomain: http://dsa.localhost:5250/admin

**Option B: Via Rails Console**
```bash
docker-compose run --rm solutions_app rails c

# In the console:
Subdomain.create!(
  name: 'dsa',
  hostname: 'dsa.localhost',
  blog_enabled: false,
  forum_enabled: false,
  tracking_enabled: true
)
```

### Step 3: Import the 30 Algorithms

Once the `dsa` subdomain is created and approved:

```bash
docker-compose run --rm solutions_app rails dsa:import
```

This will:
- Switch to the `dsa` tenant/subdomain
- Create the `algorithms` API Namespace with all required fields
- Import all 30 algorithms with complete metadata
- Show progress and summary statistics
- Display algorithms grouped by learning phase and difficulty

**Expected Output:**
```
Loading DSA seed data...
Importing 30 algorithms...
============================================================
Switched to subdomain: dsa
API Namespace 'algorithms' ready (ID: X)

Importing algorithms...
.......... [10/30]
.......... [20/30]
.......... [30/30]

============================================================
Import Complete!
Successfully imported: 30 algorithms
============================================================

Algorithms by Learning Phase:
  Phase 1 (Foundation Patterns): 5 algorithms
  Phase 2 (Core Patterns): 5 algorithms
  Phase 3 (Stack Mastery): 3 algorithms
  Phase 4 (Binary Search): 3 algorithms
  Phase 5 (Dynamic Programming): 4 algorithms
  Phase 6 (Advanced Structures): 4 algorithms
  Phase 7 (Complex Algorithms): 6 algorithms

Algorithms by Difficulty:
  Easy: 7 algorithms
  Medium: 20 algorithms
  Hard: 3 algorithms
```

### Step 4: View the Algorithms in Admin

1. Navigate to http://dsa.localhost:5250/admin
2. Go to **API Resources** → **algorithms**
3. You should see all 30 algorithms listed

### Step 5: Create Custom CMS Pages (Manual or Programmatic)

We need to create three custom pages:

#### 5.1 Algorithm Directory Page (`/algorithms`)
- Filterable list of all algorithms
- Filter by: difficulty, learning phase, data structure
- Sort by: priority, difficulty, problem number
- Display: name, difficulty, complexity, visual complexity

#### 5.2 Algorithm Detail Page (`/algorithms/:id`)
- Full algorithm information
- Problem hook and real-world analogy
- Learning objectives and key insights
- Walkthrough content (rich text)
- Practice challenges and related algorithms
- Visual/animation embed (if available)

#### 5.3 Learning Path Tracker (`/learning-path`)
- Visual representation of 7 learning phases
- Progress tracking (checkboxes for completed algorithms)
- Phase-by-phase navigation
- Recommended learning order

## Data Structure Reference

### API Namespace: `algorithms`
**Namespace Type:** `show`
**Version:** 1

### Algorithm Fields:
- `name` (string): Algorithm name
- `problem_number` (number): Unique identifier (1-30)
- `difficulty` (string): Easy | Medium | Hard
- `priority` (number): Learning priority (1-30)
- `primary_data_structure` (string): Main data structure used
- `time_complexity` (string): Big O notation
- `space_complexity` (string): Big O notation
- `prerequisites` (text): What to learn first
- `visual_complexity` (string): Low | Medium | High | Very High
- `recommended_medium` (string): Static Infographic | Animated Explainer | Interactive Simulation
- `estimated_production_time` (string): Production time estimate
- `key_visual_elements` (text): What to visualize
- `cognitive_load` (string): Low | Medium | High
- `real_world_analogy` (string): Relatable example
- `learning_domain` (string): Based on Bloom's taxonomy
- `learning_phase` (number): 1-7 (progression path)
- `problem_hook_title` (string): Engaging title
- `problem_hook_analogy` (text): Story to hook learner
- `learning_objective` (text): What student will learn
- `key_insights` (text): Important takeaways
- `practice_challenge` (text): Related practice problem
- `related_algorithms` (text): Connected algorithms
- `walkthrough_content` (richtext): Full algorithm explanation
- `production_status` (string): Not Started | In Progress | Completed
- `visual_url` (string): Link to visual/animation

## Learning Phases

1. **Foundation Patterns**: Basic array manipulation and simple data structures
2. **Core Patterns**: Essential algorithmic patterns
3. **Stack Mastery**: Stack-based problem solving
4. **Binary Search**: Search optimization techniques
5. **Dynamic Programming**: Memoization and tabulation
6. **Advanced Structures**: Linked lists, heaps, LRU cache
7. **Complex Algorithms**: Multi-dimensional and graph problems

## Troubleshooting

### Issue: Subdomain not found
**Error:** `Apartment::TenantNotFound`
**Solution:** Create the subdomain first via signup wizard or Rails console

### Issue: Import fails
**Error:** Various import errors
**Solution:**
- Ensure you're in the correct subdomain context
- Check that the API Namespace was created successfully
- Review error messages in the import output

### Issue: Can't access dsa.localhost
**Solution:**
- Ensure DNS is configured (most systems support .localhost natively)
- Try 127.0.0.1:5250 with Host header if needed
- Check that the subdomain is approved in the admin panel

## Next Development Steps

1. **Build Custom CMS Pages**: Create the three pages listed above
2. **Add Visual Content**: Create or embed visualizations for each algorithm
3. **Implement Progress Tracking**: Allow users to mark algorithms as completed
4. **Build Search/Filter UI**: Make algorithms easily discoverable
5. **Add Code Examples**: Include implementations in multiple languages
6. **Create Learning Paths**: Guided progression through the 7 phases

## Resources

- Violet Rails Docs: https://github.com/restarone/violet_rails/wiki
- API Namespace Guide: Check admin panel for API documentation
- CMS Documentation: Navigate to CMS section in admin

## Support

If you encounter issues:
1. Check Docker logs: `docker-compose logs solutions_app`
2. Rails console: `docker-compose run --rm solutions_app rails c`
3. Database console: `docker-compose run --rm solutions_app rails db`
