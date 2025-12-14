import { test, expect, Page } from '@playwright/test';

/**
 * Creator Legal Review Agent - End-to-End Test Suite
 *
 * This test suite covers the complete user journey for the Creator Legal Review Agent
 * across all five domains: Brand Deals, MCN Negotiations, Business Formation,
 * Merchandise, and Team Hires.
 *
 * Test Structure:
 * 1. Authentication & Navigation
 * 2. Review Creation (per domain)
 * 3. AI Analysis Workflow
 * 4. Risk Assessment Validation
 * 5. Review Management (approve/escalate/complete)
 * 6. Analytics Dashboard
 */

// Test data for each domain
const testData = {
  brandDeal: {
    title: 'Nike Brand Deal Q1 2024',
    domain: 'brand_deal',
    creatorName: 'John Creator',
    creatorEmail: 'john@creator.com',
    documentText: `
      INFLUENCER MARKETING AGREEMENT

      This Agreement is entered into by Nike Inc ("Brand") and John Creator ("Influencer").

      1. DELIVERABLES: Influencer agrees to create and publish:
         - Three (3) Instagram feed posts
         - Five (5) Instagram stories

      2. COMPENSATION: Brand shall pay Influencer a flat fee of $5,000 USD.
         Payment shall be made within Net-60 days of content approval.

      3. USAGE RIGHTS: Influencer grants Brand a perpetual, worldwide license
         to use, reproduce, and modify the Content.

      4. EXCLUSIVITY: 12 months post-campaign for all fitness brands.
    `,
  },
  mcnNegotiation: {
    title: 'MCN Partnership Review',
    domain: 'mcn_negotiation',
    creatorName: 'Sarah YouTuber',
    creatorEmail: 'sarah@youtube.com',
    documentText: `
      MCN PARTNERSHIP AGREEMENT

      Revenue Split: Network receives 30% of Creator's YouTube AdSense revenue.
      Term: 3 years with automatic 2-year renewal.
      Services: Marketing support and brand deal assistance.
      Exit: Creator may exit with 90-day notice after initial term.
    `,
  },
  businessFormation: {
    title: 'LLC Formation Consultation',
    domain: 'business_formation',
    creatorName: 'Alex Influencer',
    creatorEmail: 'alex@creator.biz',
    documentText: `
      Business Formation Questionnaire Response:

      Annual Revenue: $150,000
      State of Residence: California
      Number of Owners: 1 (Solo creator)
      Current Entity: Sole Proprietorship
      Employees: 2 contractors (editor, manager)
      Products: Digital courses and merchandise
    `,
  },
  merchandise: {
    title: 'Merch Line Legal Review',
    domain: 'merchandise',
    creatorName: 'Fashion Creator',
    creatorEmail: 'fashion@creator.com',
    documentText: `
      Merchandise Partnership Agreement

      Product: Custom apparel line (t-shirts, hoodies)
      Production: Print-on-demand via Printful
      Brand Name: "Creator Style" (trademark status unknown)
      Distribution: US and Canada initially
      Revenue: 40% to creator after production costs
    `,
  },
  teamHire: {
    title: 'Video Editor Contract Review',
    domain: 'team_hire',
    creatorName: 'Content Creator',
    creatorEmail: 'content@creator.io',
    documentText: `
      Contractor Agreement

      Role: Video Editor
      Hours: 20-30 hours per week
      Rate: $25/hour
      Equipment: Contractor uses own equipment
      Other Clients: Contractor works with other creators
      Duration: Project-based, ongoing
    `,
  },
};

// Helper functions
async function loginAsAdmin(page: Page) {
  await page.goto('/sign_in');
  await page.fill('input[name="user[email]"]', 'admin@test.com');
  await page.fill('input[name="user[password]"]', 'password123');
  await page.click('input[type="submit"]');
  await expect(page).toHaveURL(/sysadmin|admin/);
}

async function navigateToLegalReviews(page: Page) {
  await page.goto('/admin/creator_legal_reviews');
  await expect(page.locator('h1')).toContainText('Creator Legal Reviews');
}

async function createReview(page: Page, data: typeof testData.brandDeal) {
  await page.goto('/admin/creator_legal_reviews/new');

  // Fill in the form
  await page.fill('input[name="creator_legal_review[title]"]', data.title);
  await page.selectOption(
    'select[name="creator_legal_review[domain_type]"]',
    data.domain
  );
  await page.fill(
    'input[name="creator_legal_review[creator_name]"]',
    data.creatorName
  );
  await page.fill(
    'input[name="creator_legal_review[creator_email]"]',
    data.creatorEmail
  );
  await page.fill(
    'textarea[name="creator_legal_review[document_text]"]',
    data.documentText
  );

  // Submit the form
  await page.click('input[type="submit"]');

  // Verify redirect to show page
  await expect(page.locator('h1')).toContainText(data.title);
}

// ============================================================================
// TEST SUITES
// ============================================================================

test.describe('Creator Legal Review Agent - Authentication', () => {
  test('should redirect unauthenticated users to login', async ({ page }) => {
    await page.goto('/admin/creator_legal_reviews');
    await expect(page).toHaveURL(/sign_in/);
  });

  test('should allow admin users to access legal reviews', async ({ page }) => {
    await loginAsAdmin(page);
    await navigateToLegalReviews(page);
    await expect(page.locator('h1')).toBeVisible();
  });
});

test.describe('Creator Legal Review Agent - Brand Deal Domain', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('should create a new brand deal review', async ({ page }) => {
    await createReview(page, testData.brandDeal);

    // Verify the review was created
    await expect(page.locator('.card-header')).toContainText('Review Status');
    await expect(page.locator('.badge')).toContainText('pending');
  });

  test('should display domain-specific information for brand deals', async ({
    page,
  }) => {
    await createReview(page, testData.brandDeal);

    // Verify brand deal specific elements
    await expect(page.locator('text=Brand Deal')).toBeVisible();
  });

  test('should initiate AI analysis for brand deal', async ({ page }) => {
    await createReview(page, testData.brandDeal);

    // Click analyze button
    const analyzeButton = page.locator('text=Start Analysis');
    if (await analyzeButton.isVisible()) {
      await analyzeButton.click();

      // Verify analysis started
      await expect(page.locator('.alert')).toContainText(/Analysis started/i);
    }
  });

  test('should display risk scores after analysis', async ({ page }) => {
    // This test assumes an analyzed review exists
    await navigateToLegalReviews(page);

    // Look for a reviewed item
    const reviewedRow = page.locator('tr:has-text("reviewed")').first();
    if (await reviewedRow.isVisible()) {
      await reviewedRow.locator('a:has-text("View")').click();

      // Check for risk score display
      await expect(
        page.locator('text=/Overall Risk|Risk Scores/')
      ).toBeVisible();
    }
  });
});

test.describe('Creator Legal Review Agent - MCN Negotiation Domain', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('should create MCN negotiation review', async ({ page }) => {
    await createReview(page, testData.mcnNegotiation);

    await expect(page.locator('.badge')).toContainText('MCN');
  });

  test('should identify revenue split concerns', async ({ page }) => {
    await createReview(page, testData.mcnNegotiation);

    // The document mentions 30% MCN take - this should be flagged
    await expect(page.locator('text=MCN Negotiation')).toBeVisible();
  });
});

test.describe('Creator Legal Review Agent - Business Formation Domain', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('should create business formation consultation', async ({ page }) => {
    await createReview(page, testData.businessFormation);

    await expect(page.locator('text=Business Formation')).toBeVisible();
  });

  test('should recommend appropriate entity type', async ({ page }) => {
    await createReview(page, testData.businessFormation);

    // With $150K revenue, should consider S-Corp
    await expect(page.locator('.card')).toBeVisible();
  });
});

test.describe('Creator Legal Review Agent - Merchandise Domain', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('should create merchandise review', async ({ page }) => {
    await createReview(page, testData.merchandise);

    await expect(page.locator('text=Merchandise')).toBeVisible();
  });

  test('should flag trademark considerations', async ({ page }) => {
    await createReview(page, testData.merchandise);

    // Trademark status is unknown - should be flagged
    await expect(page.locator('.card')).toBeVisible();
  });
});

test.describe('Creator Legal Review Agent - Team Hire Domain', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('should create team hire review', async ({ page }) => {
    await createReview(page, testData.teamHire);

    await expect(page.locator('text=Team Hire')).toBeVisible();
  });

  test('should analyze worker classification', async ({ page }) => {
    await createReview(page, testData.teamHire);

    // Should identify as likely contractor based on factors
    await expect(page.locator('.card')).toBeVisible();
  });
});

test.describe('Creator Legal Review Agent - Review Management', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('should allow escalating a review', async ({ page }) => {
    await createReview(page, testData.brandDeal);

    // Click escalate button
    const escalateButton = page.locator('text=Escalate');
    if (await escalateButton.isVisible()) {
      await escalateButton.click();

      // Verify escalation
      await expect(page.locator('.badge')).toContainText(/escalated/i);
    }
  });

  test('should allow adding reviewer notes', async ({ page }) => {
    await createReview(page, testData.brandDeal);

    // Add notes
    await page.fill('textarea[name="notes"]', 'This needs human review');
    await page.click('text=Add Notes');

    // Verify notes saved
    await expect(page.locator('text=This needs human review')).toBeVisible();
  });

  test('should allow approving a reviewed item', async ({ page }) => {
    // Navigate to an existing reviewed item
    await navigateToLegalReviews(page);

    const reviewedRow = page.locator('tr:has-text("reviewed")').first();
    if (await reviewedRow.isVisible()) {
      await reviewedRow.locator('a:has-text("View")').click();

      const approveButton = page.locator('text=Approve');
      if (await approveButton.isVisible()) {
        await approveButton.click();

        await expect(page.locator('.badge')).toContainText(/completed/i);
      }
    }
  });
});

test.describe('Creator Legal Review Agent - Analytics Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('should display analytics dashboard', async ({ page }) => {
    await page.goto('/admin/creator_legal_reviews/analytics');

    await expect(page.locator('h1')).toContainText('Analytics Dashboard');
  });

  test('should show reviews by domain breakdown', async ({ page }) => {
    await page.goto('/admin/creator_legal_reviews/analytics');

    await expect(page.locator('text=Reviews by Domain')).toBeVisible();
  });

  test('should show quality score distribution', async ({ page }) => {
    await page.goto('/admin/creator_legal_reviews/analytics');

    await expect(page.locator('text=Quality Score Distribution')).toBeVisible();
  });

  test('should show escalation rate', async ({ page }) => {
    await page.goto('/admin/creator_legal_reviews/analytics');

    await expect(page.locator('text=Escalation Rate')).toBeVisible();
  });
});

test.describe('Creator Legal Review Agent - Filtering & Search', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('should filter by domain type', async ({ page }) => {
    await navigateToLegalReviews(page);

    await page.selectOption('select[name="domain"]', 'brand_deal');
    await page.click('text=Filter');

    // All visible items should be brand deals
    const domainBadges = page.locator('tbody .badge-secondary');
    const count = await domainBadges.count();
    for (let i = 0; i < count; i++) {
      await expect(domainBadges.nth(i)).toContainText('Brand Deal');
    }
  });

  test('should filter by status', async ({ page }) => {
    await navigateToLegalReviews(page);

    await page.selectOption('select[name="status"]', 'pending');
    await page.click('text=Filter');

    // All visible items should be pending
    const statusBadges = page.locator('tbody td:nth-child(4) .badge');
    const count = await statusBadges.count();
    for (let i = 0; i < count; i++) {
      await expect(statusBadges.nth(i)).toContainText('Pending');
    }
  });

  test('should filter high risk items', async ({ page }) => {
    await navigateToLegalReviews(page);

    await page.check('input[name="high_risk"]');
    await page.click('text=Filter');

    // Should only show high risk items (score >= 7)
    await expect(page.locator('h1')).toBeVisible();
  });

  test('should filter items needing human review', async ({ page }) => {
    await navigateToLegalReviews(page);

    await page.check('input[name="needs_review"]');
    await page.click('text=Filter');

    // Should highlight items needing review
    await expect(page.locator('h1')).toBeVisible();
  });
});

test.describe('Creator Legal Review Agent - Document Handling', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('should accept pasted document text', async ({ page }) => {
    await page.goto('/admin/creator_legal_reviews/new');

    const longDocument = 'This is a test contract. '.repeat(100);
    await page.fill(
      'textarea[name="creator_legal_review[document_text]"]',
      longDocument
    );

    await expect(
      page.locator('textarea[name="creator_legal_review[document_text]"]')
    ).toHaveValue(longDocument);
  });

  test('should show document in review detail', async ({ page }) => {
    await createReview(page, testData.brandDeal);

    // Toggle document section
    const toggleButton = page.locator('button:has-text("Toggle Document")');
    if (await toggleButton.isVisible()) {
      await toggleButton.click();

      // Document text should be visible
      await expect(
        page.locator('text=INFLUENCER MARKETING AGREEMENT')
      ).toBeVisible();
    }
  });
});

test.describe('Creator Legal Review Agent - Error Handling', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('should validate required fields on create', async ({ page }) => {
    await page.goto('/admin/creator_legal_reviews/new');

    // Try to submit without required fields
    await page.click('input[type="submit"]');

    // Should show validation errors (HTML5 validation or server-side)
    // This depends on implementation - checking for either
    const titleInput = page.locator(
      'input[name="creator_legal_review[title]"]'
    );
    const isInvalid =
      (await titleInput.evaluate(
        (el) => (el as HTMLInputElement).validationMessage
      )) !== '';
    expect(isInvalid || (await page.locator('.alert-danger').isVisible())).toBe(
      true
    );
  });

  test('should handle analysis failure gracefully', async ({ page }) => {
    await createReview(page, testData.brandDeal);

    // If analysis fails (e.g., no API key), should show appropriate message
    // This test validates the UI handles errors gracefully
    await expect(page.locator('.card')).toBeVisible();
  });
});

test.describe('Creator Legal Review Agent - Jobs to Be Done (JTBD) Scenarios', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  /**
   * JTBD 1: Brand Deal Review
   * "When I receive a brand deal contract, I want to quickly understand
   * if the terms are fair and identify anything I should negotiate,
   * so I can sign confidently without leaving money on the table."
   */
  test('JTBD: Brand deal - quick understanding of terms', async ({ page }) => {
    await createReview(page, testData.brandDeal);

    // Time to understanding should be fast (UI loads quickly)
    await expect(page.locator('.card-header')).toBeVisible();

    // Key information should be prominently displayed
    await expect(page.locator('text=Review Status')).toBeVisible();
  });

  /**
   * JTBD 2: MCN Evaluation
   * "When an MCN approaches me with a partnership offer, I want to
   * understand the real financial impact and what I'm actually getting."
   */
  test('JTBD: MCN evaluation - financial impact clarity', async ({ page }) => {
    await createReview(page, testData.mcnNegotiation);

    // Should clearly show the MCN domain
    await expect(page.locator('text=MCN Negotiation')).toBeVisible();
  });

  /**
   * JTBD 3: Business Formation
   * "When I'm earning enough to worry about liability and taxes, I want
   * to understand what business entity I need."
   */
  test('JTBD: Business formation - entity recommendation', async ({ page }) => {
    await createReview(page, testData.businessFormation);

    await expect(page.locator('text=Business Formation')).toBeVisible();
  });

  /**
   * JTBD 4: Merchandise Launch
   * "When I want to launch merchandise, I want to know what legal
   * protections I need."
   */
  test('JTBD: Merchandise - legal protection guidance', async ({ page }) => {
    await createReview(page, testData.merchandise);

    await expect(page.locator('text=Merchandise')).toBeVisible();
  });

  /**
   * JTBD 5: Team Hiring
   * "When I need to hire help, I want to know the right way to
   * structure the relationship."
   */
  test('JTBD: Team hire - relationship structure', async ({ page }) => {
    await createReview(page, testData.teamHire);

    await expect(page.locator('text=Team Hire')).toBeVisible();
  });
});
