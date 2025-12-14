class CreatorLegalReview < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_generator, use: :slugged

  # Validations
  validates :title, presence: true
  validates :domain_type, presence: true, inclusion: { in: %w[brand_deal mcn_negotiation business_formation merchandise team_hire] }
  validates :status, inclusion: { in: %w[pending analyzing reviewed escalated completed] }
  validates :recommended_action, inclusion: { in: %w[sign_as_is negotiate escalate_to_lawyer walk_away] }, allow_nil: true
  validates :overall_risk_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true
  validates :composite_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true
  validates_format_of :creator_email, with: Devise.email_regexp, allow_blank: true

  # Attachments for document uploads
  has_one_attached :original_document

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :analyzing, -> { where(status: 'analyzing') }
  scope :reviewed, -> { where(status: 'reviewed') }
  scope :escalated, -> { where(status: 'escalated') }
  scope :completed, -> { where(status: 'completed') }
  scope :needs_review, -> { where(needs_human_review: true) }
  scope :high_risk, -> { where('overall_risk_score >= ?', 7.0) }
  scope :by_domain, ->(domain) { where(domain_type: domain) }

  # Domain type constants and configurations
  DOMAIN_TYPES = {
    brand_deal: {
      name: 'Brand Deal',
      description: 'Contract review for brand sponsorship and influencer marketing deals',
      legal_complexity: 'medium',
      key_touchpoints: %w[term_extraction risk_identification industry_benchmarking negotiation_language],
      escalation_triggers: %w[novel_terms deal_value_above_50k cross_border litigation_risk]
    },
    mcn_negotiation: {
      name: 'MCN Negotiation',
      description: 'Multi-Channel Network partnership agreement analysis',
      legal_complexity: 'high',
      key_touchpoints: %w[revenue_split_analysis service_guarantees exit_clause_analysis term_benchmarking],
      escalation_triggers: %w[breach_implications existing_mcn_exit]
    },
    business_formation: {
      name: 'Business Formation',
      description: 'Entity selection and formation guidance for creators',
      legal_complexity: 'low_medium',
      key_touchpoints: %w[entity_recommendation state_selection formation_checklist operating_agreement],
      escalation_triggers: %w[multi_member_llc s_corp_election complex_ownership existing_liability]
    },
    merchandise: {
      name: 'Merchandise',
      description: 'Product launch legal protection and compliance review',
      legal_complexity: 'medium_high',
      key_touchpoints: %w[trademark_search pod_vs_inventory manufacturer_agreement label_compliance],
      escalation_triggers: %w[trademark_filing international_trademark product_liability_claims licensing_deals]
    },
    team_hire: {
      name: 'Team Hire',
      description: 'Worker classification and employment agreement review',
      legal_complexity: 'medium',
      key_touchpoints: %w[classification_guidance contractor_agreements ip_assignment nda_templates],
      escalation_triggers: %w[employee_handbook equity_profit_sharing worker_disputes state_specific_law termination]
    }
  }.freeze

  # Risk level configurations
  RISK_LEVELS = {
    green: { range: (0..3), label: 'Low Risk', emoji: '🟢', action: 'Proceed with confidence' },
    yellow: { range: (3..5), label: 'Moderate Risk', emoji: '🟡', action: 'Review recommended terms' },
    orange: { range: (5..7), label: 'Medium-High Risk', emoji: '🟠', action: 'Negotiate key terms' },
    red: { range: (7..10), label: 'High Risk', emoji: '🔴', action: 'Escalate or walk away' }
  }.freeze

  # Evaluation dimensions (from spec)
  EVALUATION_DIMENSIONS = {
    legal_accuracy: { weight: 0.30, description: 'Terms correctly interpreted, risks properly identified' },
    business_practicality: { weight: 0.25, description: 'Advice is actionable, considers relationship dynamics' },
    clarity: { weight: 0.20, description: 'Creator can understand and act on output' },
    completeness: { weight: 0.15, description: 'All material terms addressed, nothing critical missed' },
    calibration: { weight: 0.10, description: 'Risk scores match actual risk level' }
  }.freeze

  # Callbacks
  before_validation :set_defaults, on: :create
  after_save :notify_if_needs_review, if: -> { saved_change_to_needs_human_review? && needs_human_review? }

  # Instance methods
  def domain_config
    DOMAIN_TYPES[domain_type.to_sym]
  end

  def risk_level
    return nil unless overall_risk_score
    RISK_LEVELS.find { |_, config| config[:range].include?(overall_risk_score) }&.last
  end

  def risk_emoji
    risk_level&.dig(:emoji) || '⚪'
  end

  def risk_label
    risk_level&.dig(:label) || 'Not assessed'
  end

  def mark_as_analyzing!
    update!(status: 'analyzing')
  end

  def mark_as_reviewed!(reviewer_id: nil, notes: nil)
    update!(
      status: 'reviewed',
      reviewed_by_user_id: reviewer_id,
      reviewed_at: Time.current,
      reviewer_notes: notes
    )
  end

  def mark_as_escalated!(reason)
    update!(
      status: 'escalated',
      needs_human_review: true,
      escalation_reason: reason
    )
  end

  def mark_as_completed!
    update!(status: 'completed')
  end

  def should_escalate?
    return true if overall_risk_score && overall_risk_score >= 8.0
    return true if needs_human_review?

    triggers = domain_config&.dig(:escalation_triggers) || []
    analysis_triggers = analysis_result.dig('escalation_triggers') || []
    (triggers & analysis_triggers).any?
  end

  def calculate_composite_score
    return nil unless evaluation_scores.present?

    total = EVALUATION_DIMENSIONS.sum do |dimension, config|
      score = evaluation_scores[dimension.to_s].to_f
      score * config[:weight]
    end

    update!(composite_score: total.round(2))
    total.round(2)
  end

  def production_ready?
    composite_score.present? && composite_score >= 8.0
  end

  def acceptable_with_review?
    composite_score.present? && composite_score >= 7.0 && composite_score < 8.0
  end

  def needs_improvement?
    composite_score.present? && composite_score >= 6.0 && composite_score < 7.0
  end

  def not_acceptable?
    composite_score.present? && composite_score < 6.0
  end

  def quality_status
    return 'Not evaluated' unless composite_score
    return 'Production ready' if production_ready?
    return 'Acceptable with human review' if acceptable_with_review?
    return 'Needs improvement' if needs_improvement?
    'Not acceptable'
  end

  # Class methods for analytics
  def self.average_risk_by_domain
    group(:domain_type).average(:overall_risk_score)
  end

  def self.escalation_rate
    return 0 if count.zero?
    (escalated.count.to_f / count * 100).round(2)
  end

  def self.quality_breakdown
    {
      production_ready: where('composite_score >= ?', 8.0).count,
      acceptable_with_review: where('composite_score >= ? AND composite_score < ?', 7.0, 8.0).count,
      needs_improvement: where('composite_score >= ? AND composite_score < ?', 6.0, 7.0).count,
      not_acceptable: where('composite_score < ?', 6.0).count
    }
  end

  private

  def slug_generator
    SecureRandom.hex(10)
  end

  def set_defaults
    self.status ||= 'pending'
    self.creator_context ||= {}
    self.analysis_result ||= {}
    self.extracted_terms ||= {}
    self.risk_scores ||= {}
    self.negotiation_points ||= []
    self.evaluation_scores ||= {}
    self.ai_conversation_log ||= []
  end

  def notify_if_needs_review
    # Placeholder for notification logic
    # In production, this would send email/slack notification to legal review team
    Rails.logger.info "CreatorLegalReview #{id} requires human review: #{escalation_reason}"
  end
end
