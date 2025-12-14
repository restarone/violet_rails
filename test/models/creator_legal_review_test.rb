require "test_helper"

class CreatorLegalReviewTest < ActiveSupport::TestCase
  def setup
    @review = CreatorLegalReview.new(
      title: "Test Brand Deal Review",
      domain_type: "brand_deal",
      document_text: "Sample contract text for testing"
    )
  end

  # Validation Tests
  test "should be valid with required attributes" do
    assert @review.valid?
  end

  test "should require title" do
    @review.title = nil
    assert_not @review.valid?
    assert_includes @review.errors[:title], "can't be blank"
  end

  test "should require domain_type" do
    @review.domain_type = nil
    assert_not @review.valid?
  end

  test "should only accept valid domain types" do
    valid_domains = %w[brand_deal mcn_negotiation business_formation merchandise team_hire]

    valid_domains.each do |domain|
      @review.domain_type = domain
      assert @review.valid?, "#{domain} should be valid"
    end

    @review.domain_type = "invalid_domain"
    assert_not @review.valid?
  end

  test "should only accept valid statuses" do
    valid_statuses = %w[pending analyzing reviewed escalated completed]

    valid_statuses.each do |status|
      @review.status = status
      assert @review.valid?, "#{status} should be valid"
    end

    @review.status = "invalid_status"
    assert_not @review.valid?
  end

  test "should validate risk score range" do
    @review.overall_risk_score = -1
    assert_not @review.valid?

    @review.overall_risk_score = 11
    assert_not @review.valid?

    @review.overall_risk_score = 5.5
    assert @review.valid?
  end

  test "should validate email format if provided" do
    @review.creator_email = "invalid_email"
    assert_not @review.valid?

    @review.creator_email = "valid@email.com"
    assert @review.valid?

    @review.creator_email = nil
    assert @review.valid? # Email is optional
  end

  # Domain Configuration Tests
  test "should return correct domain config" do
    assert_equal "Brand Deal", @review.domain_config[:name]
    assert_equal "medium", @review.domain_config[:legal_complexity]
  end

  test "all domains should have configuration" do
    %w[brand_deal mcn_negotiation business_formation merchandise team_hire].each do |domain|
      @review.domain_type = domain
      assert_not_nil @review.domain_config
      assert_not_nil @review.domain_config[:name]
      assert_not_nil @review.domain_config[:key_touchpoints]
    end
  end

  # Risk Level Tests
  test "should return correct risk level for low risk" do
    @review.overall_risk_score = 2
    assert_equal "Low Risk", @review.risk_label
    assert_equal "🟢", @review.risk_emoji
  end

  test "should return correct risk level for moderate risk" do
    @review.overall_risk_score = 4
    assert_equal "Moderate Risk", @review.risk_label
    assert_equal "🟡", @review.risk_emoji
  end

  test "should return correct risk level for medium-high risk" do
    @review.overall_risk_score = 6
    assert_equal "Medium-High Risk", @review.risk_label
    assert_equal "🟠", @review.risk_emoji
  end

  test "should return correct risk level for high risk" do
    @review.overall_risk_score = 8
    assert_equal "High Risk", @review.risk_label
    assert_equal "🔴", @review.risk_emoji
  end

  test "should handle nil risk score" do
    @review.overall_risk_score = nil
    assert_equal "Not assessed", @review.risk_label
    assert_equal "⚪", @review.risk_emoji
  end

  # Status Transition Tests
  test "should mark as analyzing" do
    @review.save!
    @review.mark_as_analyzing!
    assert_equal "analyzing", @review.status
  end

  test "should mark as reviewed" do
    @review.save!
    @review.mark_as_reviewed!(reviewer_id: 1, notes: "Test notes")
    assert_equal "reviewed", @review.status
    assert_equal 1, @review.reviewed_by_user_id
    assert_equal "Test notes", @review.reviewer_notes
    assert_not_nil @review.reviewed_at
  end

  test "should mark as escalated with reason" do
    @review.save!
    @review.mark_as_escalated!("High risk terms detected")
    assert_equal "escalated", @review.status
    assert @review.needs_human_review?
    assert_equal "High risk terms detected", @review.escalation_reason
  end

  test "should mark as completed" do
    @review.save!
    @review.mark_as_completed!
    assert_equal "completed", @review.status
  end

  # Escalation Logic Tests
  test "should escalate when risk score is 8 or above" do
    @review.overall_risk_score = 8.0
    assert @review.should_escalate?
  end

  test "should not escalate when risk score is below 8" do
    @review.overall_risk_score = 7.9
    assert_not @review.should_escalate?
  end

  test "should escalate when needs human review is true" do
    @review.needs_human_review = true
    assert @review.should_escalate?
  end

  # Quality Score Tests
  test "should calculate composite score correctly" do
    @review.save!
    @review.evaluation_scores = {
      'legal_accuracy' => 8.0,
      'business_practicality' => 7.0,
      'clarity' => 9.0,
      'completeness' => 8.0,
      'calibration' => 7.0
    }
    @review.save!

    score = @review.calculate_composite_score

    # Expected: (8.0 * 0.30) + (7.0 * 0.25) + (9.0 * 0.20) + (8.0 * 0.15) + (7.0 * 0.10)
    # = 2.4 + 1.75 + 1.8 + 1.2 + 0.7 = 7.85
    assert_in_delta 7.85, score, 0.01
  end

  test "should identify production ready status" do
    @review.composite_score = 8.5
    assert @review.production_ready?
    assert_equal "Production ready", @review.quality_status
  end

  test "should identify acceptable with review status" do
    @review.composite_score = 7.5
    assert @review.acceptable_with_review?
    assert_equal "Acceptable with human review", @review.quality_status
  end

  test "should identify needs improvement status" do
    @review.composite_score = 6.5
    assert @review.needs_improvement?
    assert_equal "Needs improvement", @review.quality_status
  end

  test "should identify not acceptable status" do
    @review.composite_score = 5.5
    assert @review.not_acceptable?
    assert_equal "Not acceptable", @review.quality_status
  end

  # Scope Tests
  test "pending scope returns only pending reviews" do
    @review.status = "pending"
    @review.save!

    reviewed = CreatorLegalReview.create!(
      title: "Reviewed",
      domain_type: "brand_deal",
      status: "reviewed"
    )

    pending_reviews = CreatorLegalReview.pending
    assert_includes pending_reviews, @review
    assert_not_includes pending_reviews, reviewed
  end

  test "high_risk scope returns reviews with score >= 7" do
    @review.overall_risk_score = 8.0
    @review.save!

    low_risk = CreatorLegalReview.create!(
      title: "Low Risk",
      domain_type: "brand_deal",
      overall_risk_score: 3.0
    )

    high_risk_reviews = CreatorLegalReview.high_risk
    assert_includes high_risk_reviews, @review
    assert_not_includes high_risk_reviews, low_risk
  end

  test "by_domain scope filters correctly" do
    @review.domain_type = "brand_deal"
    @review.save!

    mcn_review = CreatorLegalReview.create!(
      title: "MCN Review",
      domain_type: "mcn_negotiation"
    )

    brand_deals = CreatorLegalReview.by_domain("brand_deal")
    assert_includes brand_deals, @review
    assert_not_includes brand_deals, mcn_review
  end

  # Analytics Tests
  test "should calculate average risk by domain" do
    CreatorLegalReview.create!(
      title: "BD 1",
      domain_type: "brand_deal",
      overall_risk_score: 6.0
    )
    CreatorLegalReview.create!(
      title: "BD 2",
      domain_type: "brand_deal",
      overall_risk_score: 8.0
    )

    averages = CreatorLegalReview.average_risk_by_domain
    assert_in_delta 7.0, averages["brand_deal"], 0.01
  end

  test "should calculate escalation rate" do
    3.times do |i|
      CreatorLegalReview.create!(
        title: "Review #{i}",
        domain_type: "brand_deal",
        status: "reviewed"
      )
    end
    CreatorLegalReview.create!(
      title: "Escalated",
      domain_type: "brand_deal",
      status: "escalated"
    )

    rate = CreatorLegalReview.escalation_rate
    assert_equal 25.0, rate
  end

  # Slug Generation Tests
  test "should generate unique slug on create" do
    @review.save!
    assert_not_nil @review.slug
    assert_match(/\A[a-f0-9]{20}\z/, @review.slug)
  end

  test "slugs should be unique" do
    @review.save!
    second_review = CreatorLegalReview.create!(
      title: "Second Review",
      domain_type: "brand_deal"
    )
    assert_not_equal @review.slug, second_review.slug
  end
end
