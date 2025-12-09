# RFC-001: Plan Mode UX for Violet App Agent

**Status:** Draft
**Author:** Violet App Agent Team
**Created:** 2025-12-09
**Related PR:** #1719

## Summary

Define the Plan Mode user experience for the Violet App Agent - a conversational interface that transforms vague app ideas into deployed, working applications. The goal is Day 0 value: watch your dream get built and buy it at an affordable price or port it wherever you want.

## Problem Statement

### Current State
When a user sends a complex request like:
> "Build me a blog about Daring To Dream with unique stories from Toronto with international origins and a story about Jai Bhagat just moving to Jersey City Heights. It should be personable like Derek Sivers, high signal like Swyx and entertaining with a right organized communication like Ramit Sethi."

The agent:
1. Processes the request (36s of API calls)
2. Returns a result with no real-time UI feedback
3. Doesn't distinguish between what it CAN do (infrastructure) vs what it CAN'T do (write content like Derek Sivers)
4. Doesn't guide the user toward actionable first steps

### The UX Gap
- **No visual feedback** during processing
- **No expectation management** on capabilities
- **No "Plan Mode"** to show what will be built before building
- **No price/hosting upsell path** to convert users to customers

## Proposed Solution: Plan Mode

### Phase 1: Understand Intent
Agent receives user input and immediately responds with:
```
Understanding your vision...

I see you want to build: A Blog
- Topic: "Daring To Dream" - Toronto stories with international origins
- Featured story: Jai Bhagat's move to Jersey City Heights
- Writing style: Derek Sivers (personable) + Swyx (high signal) + Ramit Sethi (organized storytelling)
```

### Phase 2: Scope What We Can Build
Agent clearly separates capabilities:

```
Here's what I can build for you TODAY:

[CAN BUILD]
- Blog infrastructure on your own subdomain
- Post data model (title, content, author, tags, published_at)
- Category system for "Toronto Stories", "International Origins", etc.
- Home page with latest posts
- Individual post pages
- Author profiles

[YOU'LL ADD]
- Your actual stories and content (I can provide writing frameworks)
- Featured images
- Your personal voice and style

Ready to see the plan?
```

### Phase 3: Visual Plan Preview
Show an interactive preview of what will be created:

```yaml
subdomain: daring-to-dream
app_title: Daring To Dream

namespaces:
  - name: Post
    slug: posts
    properties:
      title: String
      content: Text
      author: String
      featured_image_url: String
      tags: Array
      category: String
      published_at: DateTime
      is_featured: Boolean

  - name: Category
    slug: categories
    properties:
      name: String
      description: Text
      display_order: Integer

pages:
  - Home (latest posts, featured stories)
  - Posts Index (all published posts)
  - Post Show (individual post view)
  - Categories Index (browse by category)

[APPROVE PLAN] [MODIFY] [START OVER]
```

### Phase 4: Watch It Build (The Magic)
Real-time streaming UI showing each step:

```
Building your blog...

[1/4] Creating subdomain: daring-to-dream ✓
      → http://daring-to-dream.localhost:5250

[2/4] Creating Post namespace... ✓
      → 8 properties configured
      → API endpoint ready

[3/4] Creating Category namespace... ✓
      → 3 properties configured

[4/4] Creating pages...
      → Home page ✓
      → Posts index ✓
      → Post show ✓
      → Categories ✓

Your blog is LIVE!
→ Visit: http://daring-to-dream.localhost:5250
→ Admin: http://daring-to-dream.localhost:5250/admin
```

### Phase 5: The Upsell Path

```
Your blog is running locally. What's next?

[FREE] Keep building locally
- Continue adding features
- Perfect for development

[STARTER - $9/mo] Deploy to the cloud
- Custom domain support
- Automatic SSL
- 10GB storage

[PRO - $29/mo] Production ready
- Everything in Starter
- CDN for images
- Email notifications
- Priority support

[EXPORT] Take your code anywhere
- Download complete Rails app
- Docker configuration included
- Deploy to Heroku, AWS, or anywhere
```

## Deep Agent Framework: Plan/Act/Verify

The Violet App Agent follows the Deep Agent pattern with three phases aligned to our principles.

### Plan Phase (DIAGNOSE + MULTI-EXPERT)

**Purpose:** Understand before acting with structured questions.

```
[USER_INPUT]
    ↓
[DIAGNOSE] ← "What are you trying to build? Who is it for?"
    ↓
[SCOPE] ← Separate CAN_BUILD from YOULL_ADD
    ↓
[PLAN_PREVIEW] ← Show YAML specification
    ↓
[USER_APPROVAL] → Approve / Modify / Start Over
```

**Subagents Involved:**
- **Architect Subagent**: Data model and API design
- **Security Subagent**: Review for vulnerabilities

**Artifacts Produced:**
- App specification (YAML)
- Capability breakdown (CAN_BUILD vs YOULL_ADD)
- Estimated build steps

### Act Phase (ARTIFACT-FIRST + DOMAIN-NATIVE)

**Purpose:** Execute approved plan, producing concrete deliverables.

```
[APPROVED_PLAN]
    ↓
[create_subdomain] → ✓ Subdomain created
    ↓
[create_namespace] → ✓ Data model built (loop for each)
    ↓
[create_page] → ✓ Pages created (loop for each)
    ↓
[RESOURCES_READY]
```

**Subagents Involved:**
- **CMS Designer Subagent**: Page templates and forms
- **Deployer Subagent**: GitHub/cloud deployment

**Artifacts Produced:**
- Working subdomain URL
- Admin panel access
- API endpoints

### Verify Phase

**Purpose:** Confirm success, guide user to next steps.

```
[RESOURCES_READY]
    ↓
[VERIFY] ← Check all resources accessible
    ↓
[GUIDE_YOULL_ADD] ← Content Researcher helps with "What You'll Add"
    ↓
[UPSELL_PATH] → Hosting options
```

**Subagents Involved:**
- **Content Researcher Subagent**: Style guides and content briefs

**Artifacts Produced:**
- Verification report
- Content style guide
- Next steps checklist

## "What You'll Add" Subagents

These subagents help users with content and personal style after infrastructure is built.

### Content Researcher Subagent

Bridges the gap between infrastructure and content creation.

**Tools:**
- `research_reference_site(url, focus)` - Extract style patterns from reference sites
- `extract_writing_style(authors, descriptors)` - Create style guides from author references
- `generate_content_brief(topic, context, style)` - Produce actionable content briefs

**Use Cases:**
- User says "like Derek Sivers" → Extract Sivers' writing patterns
- User provides chaiwithjai.com → Research site for tone and topics
- User needs first blog post → Generate content brief with hook

**Example Flow:**
```
User: "Make it personable like Derek Sivers, high signal like Swyx"

Content Researcher:
1. extract_writing_style("Derek Sivers, Swyx", "personable, high-signal")
2. Returns:
   # Style Guide: Daring To Dream

   ## Voice Summary
   Short paragraphs. Counterintuitive insights. Dense with value.

   ## Do's
   - One sentence paragraphs for impact
   - Start with specific moments, not generalizations
   - Learning in public transparency

   ## Don'ts
   - No filler words or throat-clearing
   - No generic advice without examples
   - No walls of text
```

## E2E Test Case: Daring To Dream Blog

Reference request:
> "Build me a blog about Daring To Dream and tell unique stories from Toronto with international origins and a story about Jai Bhagat (chaiwithjai.com) just moving to Jersey City Heights in November 2025. It should be personable like Derek Sivers, high signal like Swyx and entertaining with organized storytelling like Ramit Sethi."

### Plan Phase Output

```yaml
subdomain: daring-to-dream
app_title: Daring To Dream

capability_breakdown:
  can_build:
    - Blog infrastructure (subdomain, admin)
    - Post model (title, content, author, category, tags)
    - Category model (Toronto Stories, International Origins)
    - Author profile support
    - Home page with featured posts
    - Individual post pages

  youll_add:
    - Story about Jai Bhagat's move to Jersey City
    - Your personal voice and style
    - Featured images
    - Actual blog content

namespaces:
  - name: Post
    properties:
      title: String
      content: Text
      author: String
      category: String
      tags: Array
      featured: Boolean
      published_at: DateTime

  - name: Category
    properties:
      name: String
      description: Text
      display_order: Integer

pages:
  - Home (latest/featured posts)
  - Posts Index
  - Post Show
  - Categories
```

### Act Phase Output

```
Building your blog...

[1/6] Creating subdomain: daring-to-dream ✓
      → http://daring-to-dream.localhost:5250

[2/6] Creating Post namespace... ✓
      → 8 properties configured

[3/6] Creating Category namespace... ✓
      → 3 properties configured

[4/6] Creating home page... ✓
[5/6] Creating posts index... ✓
[6/6] Creating post show page... ✓

Your blog is LIVE!
```

### Verify Phase Output

```
✓ All resources verified

Your blog is ready at: http://daring-to-dream.localhost:5250

## What You'll Add

I've analyzed your style references:

**Style Guide: Daring To Dream**

Blending: Derek Sivers (minimalist insight) + Swyx (dense value) + Ramit Sethi (organized storytelling)

### First Post: Jai Bhagat's Story

Based on chaiwithjai.com research:
- Jai is an AI product engineer, Replit alum
- Anti-guru philosophy: "trust your instincts"
- Story angle: Jersey City Heights as fresh start

**Content Brief:**
- Hook: Specific moment (November 2025, first night in JC Heights)
- Setup: Why leave Toronto? What does "international origins" mean?
- Journey: The decision process, the doubts, the clarity
- Insight: What "daring to dream" really means

Ready to write your first post?
```

## Technical Implementation

### 1. Streaming UI (Priority 1)
Replace synchronous POST with Server-Sent Events:
```javascript
// Current (broken)
const response = await fetch('/threads/{id}/runs', { method: 'POST' });
const result = await response.json();

// Proposed (streaming)
const eventSource = new EventSource('/threads/{id}/runs/stream');
eventSource.onmessage = (event) => {
  updateUI(JSON.parse(event.data));
};
```

### 2. Plan State Machine
```
[USER_INPUT] → [UNDERSTANDING] → [SCOPING] → [PLAN_PREVIEW]
                                                    ↓
                                            [USER_APPROVAL]
                                                    ↓
                                            [BUILDING] → [COMPLETE]
                                                    ↓
                                            [UPSELL_PROMPT]
```

### 3. Capability Classification
Train the agent to recognize:
- **Infrastructure requests** → Can do: "Create a blog", "Add comments to posts"
- **Content requests** → Guide: "Write like Derek Sivers" → provide frameworks
- **Style requests** → Templates: "Make it look modern" → use theme templates
- **Hybrid requests** → Split: Handle infrastructure, guide on content

### 4. Progress Events
Emit granular events during building:
```json
{ "type": "step_start", "step": "create_subdomain", "name": "daring-to-dream" }
{ "type": "step_complete", "step": "create_subdomain", "url": "http://daring-to-dream.localhost:5250" }
{ "type": "step_start", "step": "create_namespace", "name": "Post" }
{ "type": "step_complete", "step": "create_namespace", "properties_count": 8 }
```

## User Stories

### Story 1: First-Time Builder
**As a** non-technical user with a blog idea
**I want to** describe my vision in plain English
**So that** I can see my app get built without writing code

### Story 2: Validation Before Action
**As a** user investing time in app building
**I want to** preview the plan before execution
**So that** I can correct misunderstandings early

### Story 3: Understand Capabilities
**As a** user with ambitious ideas
**I want to** know what the agent can and can't do
**So that** I have realistic expectations

### Story 4: Watch the Magic
**As a** user who just approved a plan
**I want to** see real-time progress of my app being built
**So that** I feel engaged and trust the process

### Story 5: Path to Production
**As a** user with a working local app
**I want to** easily deploy to production
**So that** I can share my creation with the world

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Time to first "wow" | ~45s (hidden) | <5s (visible progress) |
| User understands scope | 0% (no feedback) | 95% (explicit plan) |
| Plan approval rate | N/A | >80% |
| Conversion to paid | N/A | >5% |
| Export/port requests | N/A | Track as alternative success |

## Open Questions

1. **Plan modification UX**: How do users modify the plan? Text input? Visual editor?
2. **Content assistance**: Should we offer AI writing frameworks for the "YOU'LL ADD" sections?
3. **Template gallery**: Pre-built app templates for common patterns (blog, portfolio, etc.)?
4. **Pricing model**: Per-app? Per-subdomain? Subscription?
5. **Export format**: Full Rails app? Simplified static version?

## Next Steps

1. [ ] Implement streaming UI for real-time feedback
2. [ ] Add Plan Preview state to agent graph
3. [ ] Create capability classifier for intent routing
4. [ ] Design and build progress event system
5. [ ] Build upsell flow and pricing page
6. [ ] User testing with 5 non-technical users

## Appendix: Request Analysis

The original request was:
> "Build me a blog about Daring To Dream and tell unique stories from Toronto with international origins and a story about Jai Bhagat (chaiwithjai.com) just moving to Jersey City Heights in November 2025. It should be personable like Derek Sivers, high signal like Swyx and entertaining with a right organized communication and story telling like Ramit Sethi."

**Can Build:**
- Blog subdomain and data model
- Post, Category, Author namespaces
- Home and post pages

**Cannot Build (but can guide):**
- Actual story content about Jai Bhagat
- Derek Sivers/Swyx/Ramit Sethi writing style (can provide frameworks)
- "International origins" narrative (can create category structure)

**Plan Mode would have:**
1. Acknowledged the vision immediately
2. Separated infrastructure (can do) from content (user creates)
3. Shown what the blog structure would look like
4. Let user approve before building
5. Streamed progress while creating
6. Offered hosting/deployment path
