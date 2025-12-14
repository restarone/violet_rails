# Creator Legal Review Agent

## Overview

The Creator Legal Review Agent is an AI-powered legal analysis system designed to help content creators navigate complex legal documents across five key domains:

1. **Brand Deals** - Sponsorship and influencer marketing contracts
2. **MCN Negotiations** - Multi-Channel Network partnership agreements
3. **Business Formation** - Entity selection and formation guidance
4. **Merchandise** - Product launch legal protection and compliance
5. **Team Hires** - Worker classification and employment agreements

## Architecture

### Evaluation-First Architecture

The system implements an evaluation-first approach with multiple feedback loops:

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INPUT                                │
│              (Contract PDF, question, context)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     INITIAL ANALYSIS                             │
│                    (Primary LLM Pass)                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   MID-LOOP EVALUATION                            │
│    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│    │   Legal     │  │  Business   │  │  Industry   │           │
│    │   Expert    │  │   Expert    │  │   Expert    │           │
│    │   (LLM)     │  │   (LLM)     │  │   (LLM)     │           │
│    └──────┬──────┘  └──────┬──────┘  └──────┬──────┘           │
│           └────────────────┼────────────────┘                    │
│                            │                                     │
│                   Refinement Needed? ───► Loop back if yes       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FINAL OUTPUT                                │
│         (Analysis, recommendations, risk scores)                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   END-LOOP EVALUATION                            │
│              (Multidimensional Scorecard)                        │
│                                                                  │
│   Legal Accuracy (30%) │ Business Practicality (25%)            │
│   Clarity (20%)        │ Completeness (15%)                     │
│   Calibration (10%)    │                                        │
└─────────────────────────────────────────────────────────────────┘
```

### System Components

#### 1. CreatorLegalReview Model (`app/models/creator_legal_review.rb`)

The core data model that stores:
- Review metadata (title, domain, status)
- Creator context (follower count, platform, niche)
- Document text and metadata
- AI analysis results
- Risk scores and evaluation scores
- Audit trail (conversation log, processing time)

#### 2. CreatorLegalReviewService (`app/services/creator_legal_review_service.rb`)

The AI analysis service that:
- Performs initial analysis using Claude API
- Runs mid-loop evaluation with expert personas
- Generates domain-specific outputs
- Calculates composite quality scores
- Determines escalation requirements

#### 3. Admin Controller (`app/controllers/admin/creator_legal_reviews_controller.rb`)

Handles the web interface for:
- Creating new reviews
- Uploading and parsing documents (PDF, DOCX, TXT)
- Triggering AI analysis
- Managing review workflow (approve, escalate, add notes)
- Viewing analytics

#### 4. Background Job (`app/jobs/analyze_creator_legal_review_job.rb`)

Processes AI analysis asynchronously to prevent request timeouts.

## Setup

### Prerequisites

1. Ruby 2.6.6+ (Rails 6.1)
2. PostgreSQL database
3. Redis (for Sidekiq background jobs)
4. Anthropic API key for Claude

### Installation

1. Add the required gems (already added in Gemfile):
```ruby
gem "pdf-reader", "~> 2.11"  # For parsing PDF contracts
gem "docx", "~> 0.8"          # For parsing DOCX contracts
```

2. Run migrations:
```bash
rails db:migrate
```

3. Set environment variables:
```bash
export ANTHROPIC_API_KEY=your_api_key_here
```

4. Start Sidekiq for background processing:
```bash
bundle exec sidekiq
```

## Usage

### Creating a Review

1. Navigate to `/admin/creator_legal_reviews`
2. Click "New Review"
3. Fill in:
   - **Title**: Descriptive name for the review
   - **Domain Type**: Select from the 5 domains
   - **Creator Information**: Name, email, context (JSON)
   - **Document**: Upload file or paste text

### Running Analysis

1. From the review detail page, click "Start Analysis"
2. Analysis runs in the background (typically 1-3 minutes)
3. Refresh to see results including:
   - Plain English summary
   - Risk scores by category
   - Overall risk assessment
   - Recommended action
   - Negotiation talking points

### Review Workflow

| Status | Description | Actions Available |
|--------|-------------|-------------------|
| Pending | Review created, awaiting analysis | Start Analysis, Edit, Delete |
| Analyzing | AI analysis in progress | Wait |
| Reviewed | Analysis complete | Approve, Escalate, Add Notes |
| Escalated | Flagged for human lawyer review | Add Notes |
| Completed | Review finalized | View Only |

### Risk Levels

| Level | Score Range | Emoji | Recommended Action |
|-------|-------------|-------|-------------------|
| Low | 0-3 | 🟢 | Proceed with confidence |
| Moderate | 3-5 | 🟡 | Review recommended terms |
| Medium-High | 5-7 | 🟠 | Negotiate key terms |
| High | 7-10 | 🔴 | Escalate or walk away |

### Quality Thresholds

The system evaluates output quality on 5 dimensions:

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Legal Accuracy | 30% | Terms correctly interpreted, risks properly identified |
| Business Practicality | 25% | Advice is actionable, considers relationship dynamics |
| Clarity | 20% | Creator can understand and act on output |
| Completeness | 15% | All material terms addressed |
| Calibration | 10% | Risk scores match actual risk level |

**Quality Status:**
- **Production Ready**: Composite score ≥ 8.0
- **Acceptable with Review**: Score 7.0 - 7.9
- **Needs Improvement**: Score 6.0 - 6.9
- **Not Acceptable**: Score < 6.0

## Domain-Specific Features

### Brand Deals

Analyzes:
- Compensation (base fee, payment timing, kill fee)
- Deliverables (content type, quantity, platforms)
- IP & Usage Rights (ownership, license scope, duration)
- Exclusivity (category, duration, geography)
- Termination (exit conditions, morals clause)

Red Flags:
- Perpetual, worldwide usage rights
- Broad category exclusivity > 6 months
- Unilateral termination rights
- Payment "upon approval" with no timeline

### MCN Negotiations

Analyzes:
- Revenue structure (actual creator take after YouTube's cut)
- Term and exit conditions
- Services promised vs. contractually guaranteed
- Channel ownership post-termination

Red Flags:
- MCN takes % of non-YouTube revenue
- Term > 3 years with no exit
- Channel ownership unclear
- Exit penalties

### Business Formation

Provides:
- Entity type recommendation (LLC, S-Corp, etc.)
- State selection guidance
- Formation checklist
- Tax implications overview

Recommendations based on:
- Annual revenue
- Number of owners
- Employee status
- Product type (digital vs. physical)

### Merchandise

Analyzes:
- Trademark status and filing needs
- Manufacturer agreement terms
- Product liability assessment
- Labeling compliance requirements

Considerations:
- POD vs. inventory tradeoffs
- Insurance requirements
- CPSIA compliance (children's products)

### Team Hires

Analyzes:
- Worker classification (1099 vs. W-2)
- Classification risk factors
- Agreement essentials (scope, IP, termination)

Classification factors:
- Behavioral control
- Financial control
- Relationship type

## API Integration

### Claude API Configuration

The service uses Claude 3 Opus via the Anthropic API:

```ruby
HTTParty.post(
  'https://api.anthropic.com/v1/messages',
  headers: {
    'Content-Type' => 'application/json',
    'x-api-key' => ENV['ANTHROPIC_API_KEY'],
    'anthropic-version' => '2023-06-01'
  },
  body: { model: 'claude-3-opus-20240229', ... }
)
```

### Extending Prompts

Domain-specific prompts are defined in `CreatorLegalReviewService`:

```ruby
def domain_templates
  {
    brand_deal: brand_deal_template,
    mcn_negotiation: mcn_negotiation_template,
    # ...
  }
end
```

## Testing

### Running E2E Tests

```bash
cd e2e
npm install
npm test
```

### Test Suites

| Suite | Command | Description |
|-------|---------|-------------|
| All Tests | `npm test` | Full test suite |
| Brand Deals | `npm run test:brand-deals` | Brand deal domain tests |
| MCN | `npm run test:mcn` | MCN negotiation tests |
| Business | `npm run test:business` | Business formation tests |
| Merchandise | `npm run test:merchandise` | Merchandise domain tests |
| Team Hire | `npm run test:team-hire` | Team hire domain tests |
| JTBD | `npm run test:jtbd` | Jobs-to-be-done scenarios |

### Benchmark Test Suite

Located in `lib/creator_legal_review/benchmark_test_suite.rb`:

```ruby
CreatorLegalReview::BenchmarkTestSuite.all_test_cases
# Returns 31 test cases across all domains

CreatorLegalReview::BenchmarkTestSuite.validate_result(test_case, result)
# Validates analysis against expected outputs
```

## Escalation Rules

Reviews are automatically escalated when:
1. Overall risk score ≥ 8.0
2. Composite quality score < 7.0
3. Domain-specific escalation triggers are detected:
   - Brand Deals: Novel terms, deal value > $50K, cross-border
   - MCN: Breach implications, existing MCN exit
   - Business Formation: Multi-member LLC, complex ownership
   - Merchandise: Trademark filing, product liability claims
   - Team Hires: Equity/profit sharing, worker disputes

## Analytics Dashboard

Access at `/admin/creator_legal_reviews/analytics`:

- Total reviews count
- Reviews by domain breakdown
- Reviews by status distribution
- Average risk by domain
- Escalation rate
- Quality score distribution
- Recent reviews list

## Security Considerations

1. **Data Protection**: Contract text is stored in the database; ensure appropriate access controls
2. **API Keys**: Store ANTHROPIC_API_KEY securely (not in version control)
3. **Authentication**: Admin routes require `global_admin` user role
4. **Audit Trail**: All AI conversations are logged for transparency

## Future Enhancements

1. **Document OCR**: Support for scanned PDF contracts
2. **Webhook Notifications**: Alert when reviews need attention
3. **Custom Benchmarks**: Allow users to define domain-specific test cases
4. **Multi-language Support**: Analyze contracts in other languages
5. **Historical Analysis**: Track changes across contract versions
6. **Integration APIs**: Allow external systems to submit reviews

## Troubleshooting

### Analysis Not Starting
- Check that `ANTHROPIC_API_KEY` is set
- Verify Sidekiq is running
- Check Sidekiq logs for errors

### Poor Quality Scores
- Ensure document text is complete and well-formatted
- Provide creator context for better analysis
- Review AI conversation log for insights

### Escalation Not Triggering
- Check escalation triggers in domain config
- Verify risk scores are being calculated
- Review the `should_escalate?` method logic

## Support

For issues or feature requests, please open a GitHub issue or contact the development team.
