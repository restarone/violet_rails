class CreateCreatorLegalReviews < ActiveRecord::Migration[6.1]
  def change
    create_table :creator_legal_reviews do |t|
      # Core identification
      t.string :slug, null: false
      t.string :title, null: false
      t.string :status, default: 'pending' # pending, analyzing, reviewed, escalated, completed

      # Domain categorization (5 domains from spec)
      t.string :domain_type, null: false # brand_deal, mcn_negotiation, business_formation, merchandise, team_hire

      # Creator context
      t.string :creator_email
      t.string :creator_name
      t.jsonb :creator_context, default: {} # follower_count, platform, niche, previous_deals, etc.

      # Input documents
      t.text :document_text # Extracted text from uploaded contract/document
      t.jsonb :document_metadata, default: {} # original filename, upload date, etc.

      # AI Analysis Results
      t.jsonb :analysis_result, default: {} # Full structured analysis
      t.jsonb :extracted_terms, default: {} # Material terms extracted
      t.jsonb :risk_scores, default: {} # Risk scores per category
      t.decimal :overall_risk_score, precision: 3, scale: 1 # 0.0 - 10.0
      t.text :plain_english_summary
      t.jsonb :negotiation_points, default: [] # Suggested negotiation talking points
      t.string :recommended_action # sign_as_is, negotiate, escalate_to_lawyer, walk_away

      # Evaluation scores (multi-dimensional scorecard)
      t.jsonb :evaluation_scores, default: {} # legal_accuracy, business_practicality, clarity, completeness, calibration
      t.decimal :composite_score, precision: 3, scale: 2

      # Human review
      t.boolean :needs_human_review, default: false
      t.text :escalation_reason
      t.bigint :reviewed_by_user_id
      t.datetime :reviewed_at
      t.text :reviewer_notes

      # Audit trail
      t.jsonb :ai_conversation_log, default: [] # Full conversation with AI for transparency
      t.string :ai_model_used
      t.integer :processing_time_ms

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :creator_legal_reviews, :slug, unique: true
    add_index :creator_legal_reviews, :status
    add_index :creator_legal_reviews, :domain_type
    add_index :creator_legal_reviews, :creator_email
    add_index :creator_legal_reviews, :recommended_action
    add_index :creator_legal_reviews, :needs_human_review
    add_index :creator_legal_reviews, :deleted_at
    add_index :creator_legal_reviews, :overall_risk_score
  end
end
