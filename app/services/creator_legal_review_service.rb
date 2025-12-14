class CreatorLegalReviewService
  attr_reader :review, :conversation_log

  # Error classes
  class AnalysisError < StandardError; end
  class ConfigurationError < StandardError; end

  def initialize(review)
    @review = review
    @conversation_log = []
    @start_time = Time.current
  end

  def analyze!
    validate_configuration!
    review.mark_as_analyzing!

    begin
      # Step 1: Initial Analysis
      initial_analysis = perform_initial_analysis
      log_conversation('initial_analysis', initial_analysis)

      # Step 2: Mid-Loop Evaluation (expert personas)
      evaluation_result = perform_mid_loop_evaluation(initial_analysis)
      log_conversation('mid_loop_evaluation', evaluation_result)

      # Step 3: Refinement if needed
      if needs_refinement?(evaluation_result)
        refined_analysis = perform_refinement(initial_analysis, evaluation_result)
        log_conversation('refinement', refined_analysis)
        initial_analysis = refined_analysis
      end

      # Step 4: Generate Final Output
      final_output = generate_final_output(initial_analysis)
      log_conversation('final_output', final_output)

      # Step 5: End-Loop Evaluation (scoring)
      scores = perform_end_loop_evaluation(final_output)
      log_conversation('end_loop_evaluation', scores)

      # Step 6: Save Results
      save_results!(final_output, scores)

      # Step 7: Check for escalation
      check_and_escalate! if review.should_escalate?

      { success: true, review: review.reload }
    rescue => e
      handle_error(e)
    end
  end

  private

  def validate_configuration!
    raise ConfigurationError, "ANTHROPIC_API_KEY not configured" unless anthropic_api_key.present?
    raise ConfigurationError, "Review document text is required" unless review.document_text.present?
  end

  def anthropic_api_key
    ENV['ANTHROPIC_API_KEY']
  end

  def perform_initial_analysis
    prompt = build_initial_analysis_prompt
    response = call_claude(prompt, system: initial_analysis_system_prompt)
    parse_structured_response(response)
  end

  def perform_mid_loop_evaluation(analysis)
    evaluations = {}

    # Legal Expert Evaluation
    legal_prompt = build_legal_expert_prompt(analysis)
    evaluations[:legal_expert] = call_claude(legal_prompt, system: legal_expert_system_prompt)

    # Business Expert Evaluation
    business_prompt = build_business_expert_prompt(analysis)
    evaluations[:business_expert] = call_claude(business_prompt, system: business_expert_system_prompt)

    parse_evaluation_response(evaluations)
  end

  def needs_refinement?(evaluation_result)
    avg_score = evaluation_result.values.map { |v| v[:score].to_f }.sum / evaluation_result.size
    avg_score < 4.0 # On scale of 1-5, refine if below 4
  end

  def perform_refinement(initial_analysis, evaluation_result)
    prompt = build_refinement_prompt(initial_analysis, evaluation_result)
    response = call_claude(prompt, system: initial_analysis_system_prompt)
    parse_structured_response(response)
  end

  def generate_final_output(analysis)
    prompt = build_final_output_prompt(analysis)
    response = call_claude(prompt, system: final_output_system_prompt)
    parse_final_output(response)
  end

  def perform_end_loop_evaluation(final_output)
    prompt = build_end_loop_evaluation_prompt(final_output)
    response = call_claude(prompt, system: evaluator_system_prompt)
    parse_scores(response)
  end

  def save_results!(final_output, scores)
    processing_time = ((Time.current - @start_time) * 1000).to_i

    review.update!(
      status: 'reviewed',
      analysis_result: final_output[:full_analysis],
      extracted_terms: final_output[:extracted_terms],
      risk_scores: final_output[:risk_scores],
      overall_risk_score: final_output[:overall_risk_score],
      plain_english_summary: final_output[:summary],
      negotiation_points: final_output[:negotiation_points],
      recommended_action: final_output[:recommended_action],
      evaluation_scores: scores,
      ai_conversation_log: @conversation_log,
      ai_model_used: 'claude-3-opus-20240229',
      processing_time_ms: processing_time
    )

    review.calculate_composite_score
  end

  def check_and_escalate!
    reason = determine_escalation_reason
    review.mark_as_escalated!(reason)
  end

  def determine_escalation_reason
    reasons = []
    reasons << "High overall risk score: #{review.overall_risk_score}" if review.overall_risk_score >= 8.0
    reasons << "Low composite quality score: #{review.composite_score}" if review.composite_score && review.composite_score < 7.0
    reasons << "Complex terms requiring human review" if review.analysis_result['escalation_triggers']&.any?
    reasons.join("; ")
  end

  def handle_error(error)
    log_conversation('error', { message: error.message, backtrace: error.backtrace.first(5) })

    review.update!(
      status: 'pending',
      ai_conversation_log: @conversation_log,
      needs_human_review: true,
      escalation_reason: "Analysis failed: #{error.message}"
    )

    { success: false, error: error.message }
  end

  def log_conversation(step, data)
    @conversation_log << {
      step: step,
      timestamp: Time.current.iso8601,
      data: data
    }
  end

  def call_claude(prompt, system: nil)
    # Using HTTParty for API calls (already in Gemfile)
    response = HTTParty.post(
      'https://api.anthropic.com/v1/messages',
      headers: {
        'Content-Type' => 'application/json',
        'x-api-key' => anthropic_api_key,
        'anthropic-version' => '2023-06-01'
      },
      body: {
        model: 'claude-3-opus-20240229',
        max_tokens: 4096,
        system: system,
        messages: [{ role: 'user', content: prompt }]
      }.to_json,
      timeout: 120
    )

    if response.success?
      response.parsed_response['content'].first['text']
    else
      raise AnalysisError, "Claude API error: #{response.code} - #{response.message}"
    end
  end

  # System prompts for different analysis stages
  def initial_analysis_system_prompt
    domain_config = review.domain_config
    <<~PROMPT
      You are a legal analysis AI specialized in #{domain_config[:name]} contracts for content creators.
      Your task is to analyze documents and extract structured information.

      Legal Complexity Level: #{domain_config[:legal_complexity]}
      Key Analysis Areas: #{domain_config[:key_touchpoints].join(', ')}

      Output your analysis in valid JSON format with the following structure:
      {
        "parties": {},
        "material_terms": {},
        "risk_areas": [],
        "key_findings": [],
        "escalation_triggers": []
      }

      Be thorough but practical. Focus on what matters most to creators.
    PROMPT
  end

  def legal_expert_system_prompt
    <<~PROMPT
      You are a contract law expert evaluating AI-generated legal analysis for accuracy.

      Evaluate on these criteria (score 1-5 each):
      1. Term Extraction Accuracy: Were all material terms correctly identified?
      2. Legal Interpretation: Is the plain-English explanation legally accurate?
      3. Risk Assessment: Is the risk score calibrated correctly?
      4. Completeness: Were any important clauses missed?

      Output JSON: {"term_extraction": X, "legal_interpretation": X, "risk_assessment": X, "completeness": X, "feedback": "...", "score": X}
    PROMPT
  end

  def business_expert_system_prompt
    <<~PROMPT
      You are a creator economy business expert evaluating legal analysis for practical relevance.

      Evaluate on these criteria (score 1-5 each):
      1. Practical Relevance: Does advice account for creator's business reality?
      2. Negotiability Assessment: Are suggestions actually achievable?
      3. Opportunity Cost: Does analysis consider deal value vs. risk?
      4. Career Impact: Are long-term implications considered?

      Output JSON: {"practical_relevance": X, "negotiability": X, "opportunity_cost": X, "career_impact": X, "feedback": "...", "score": X}
    PROMPT
  end

  def final_output_system_prompt
    domain_templates[review.domain_type.to_sym] || default_output_template
  end

  def evaluator_system_prompt
    <<~PROMPT
      You are evaluating the final output of a legal review AI system.

      Score each dimension from 0-10:
      - legal_accuracy (30% weight): Terms correctly interpreted, risks properly identified
      - business_practicality (25% weight): Advice is actionable, considers relationship dynamics
      - clarity (20% weight): Creator can understand and act on output
      - completeness (15% weight): All material terms addressed, nothing critical missed
      - calibration (10% weight): Risk scores match actual risk level

      Output JSON: {"legal_accuracy": X, "business_practicality": X, "clarity": X, "completeness": X, "calibration": X}
    PROMPT
  end

  # Domain-specific templates
  def domain_templates
    {
      brand_deal: brand_deal_template,
      mcn_negotiation: mcn_negotiation_template,
      business_formation: business_formation_template,
      merchandise: merchandise_template,
      team_hire: team_hire_template
    }
  end

  def brand_deal_template
    <<~PROMPT
      You are generating the final output for a Brand Deal contract review.

      Structure your response as JSON with:
      {
        "extracted_terms": {
          "compensation": {"base_fee": "", "payment_timing": "", "kill_fee": "", "risk_score": ""},
          "deliverables": {"content_type": "", "quantity": "", "platforms": [], "revision_rounds": "", "risk_score": ""},
          "ip_and_usage": {"ownership": "", "license_duration": "", "license_scope": "", "modification_rights": "", "risk_score": ""},
          "exclusivity": {"category": "", "duration": "", "geography": "", "risk_score": ""},
          "termination": {"creator_can_exit": "", "brand_can_exit": "", "morals_clause": "", "cure_period": "", "risk_score": ""}
        },
        "risk_scores": {
          "compensation": 0-10,
          "deliverables": 0-10,
          "ip_and_usage": 0-10,
          "exclusivity": 0-10,
          "termination": 0-10
        },
        "overall_risk_score": 0-10,
        "summary": "Plain English summary...",
        "negotiation_points": ["point1", "point2"],
        "recommended_action": "sign_as_is|negotiate|escalate_to_lawyer|walk_away",
        "full_analysis": {},
        "escalation_triggers": []
      }

      Risk Score Guide:
      - 0-3 (Green): Low risk, creator-friendly terms
      - 3-5 (Yellow): Moderate risk, standard terms
      - 5-7 (Orange): Medium-high risk, should negotiate
      - 7-10 (Red): High risk, predatory terms
    PROMPT
  end

  def mcn_negotiation_template
    <<~PROMPT
      You are generating the final output for an MCN Partnership Agreement review.

      Structure your response as JSON with:
      {
        "extracted_terms": {
          "network_info": {"name": "", "reputation_notes": ""},
          "revenue_structure": {"adsense_split": "", "effective_creator_take": "", "sponsorship_handling": "", "risk_score": ""},
          "term_and_exit": {"initial_term": "", "auto_renewal": "", "exit_conditions": [], "penalty_for_exit": "", "risk_score": ""},
          "services_promised": {"guaranteed_in_contract": [], "mentioned_not_guaranteed": [], "risk_score": ""},
          "channel_ownership": {"who_owns_channel": "", "content_rights": "", "post_termination": "", "risk_score": ""}
        },
        "risk_scores": {"revenue": 0-10, "term": 0-10, "services": 0-10, "ownership": 0-10},
        "overall_risk_score": 0-10,
        "revenue_calculation": {"gross_example": 10000, "youtube_cut": 4500, "mcn_cut": 0, "creator_receives": 0, "effective_percentage": 0},
        "summary": "Plain English summary...",
        "negotiation_points": [],
        "recommended_action": "sign_as_is|negotiate|escalate_to_lawyer|walk_away",
        "full_analysis": {},
        "escalation_triggers": []
      }
    PROMPT
  end

  def business_formation_template
    <<~PROMPT
      You are generating the final output for a Business Formation consultation.

      Structure your response as JSON with:
      {
        "creator_profile": {"annual_revenue": "", "state": "", "number_of_owners": "", "employees": "", "physical_products": ""},
        "recommendation": {
          "entity_type": "sole_prop|single_member_llc|multi_member_llc|s_corp",
          "formation_state": "",
          "reasoning": "",
          "estimated_cost": ""
        },
        "decision_factors": {
          "liability_protection": "",
          "tax_treatment": "",
          "complexity": ""
        },
        "s_corp_analysis": {"recommended": true/false, "threshold_income": "", "reasoning": ""},
        "next_steps": {"immediate": [], "within_30_days": [], "ongoing_compliance": []},
        "risk_scores": {"liability": 0-10, "tax": 0-10, "compliance": 0-10},
        "overall_risk_score": 0-10,
        "summary": "",
        "recommended_action": "proceed|consult_accountant|consult_lawyer",
        "full_analysis": {},
        "escalation_triggers": []
      }
    PROMPT
  end

  def merchandise_template
    <<~PROMPT
      You are generating the final output for a Merchandise Launch legal review.

      Structure your response as JSON with:
      {
        "product_info": {"type": "", "production_model": ""},
        "trademark_status": {"brand_name_search": "", "logo_search": "", "filing_recommended": "", "classes_to_file": []},
        "manufacturer_agreement": {"key_terms": {}, "risk_score": ""},
        "product_liability": {"risk_level": "", "insurance_recommended": "", "coverage_type": "", "estimated_cost": ""},
        "compliance_requirements": {"labeling": [], "special_requirements": []},
        "risk_scores": {"trademark": 0-10, "liability": 0-10, "compliance": 0-10, "manufacturing": 0-10},
        "overall_risk_score": 0-10,
        "summary": "",
        "negotiation_points": [],
        "recommended_action": "proceed|trademark_first|insurance_first|escalate_to_lawyer",
        "full_analysis": {},
        "escalation_triggers": []
      }
    PROMPT
  end

  def team_hire_template
    <<~PROMPT
      You are generating the final output for a Team Hire / Worker Classification review.

      Structure your response as JSON with:
      {
        "worker_info": {"role": "", "work_description": "", "hours_per_week": "", "duration": ""},
        "classification_factors": {
          "behavioral_control": {"creator_controls_how": "", "set_schedule": "", "tools_required": ""},
          "financial_control": {"payment_method": "", "other_clients": "", "own_equipment": "", "profit_loss_opportunity": ""},
          "relationship_type": {"written_contract": "", "benefits": "", "ongoing": "", "key_to_business": ""}
        },
        "classification_result": {"recommended": "independent_contractor|employee", "confidence": "", "misclassification_risk": ""},
        "agreement_essentials": {"scope_of_work": "", "compensation": "", "ip_assignment": "", "confidentiality": "", "termination": ""},
        "risk_scores": {"classification": 0-10, "ip_protection": 0-10, "compliance": 0-10},
        "overall_risk_score": 0-10,
        "next_steps": [],
        "summary": "",
        "recommended_action": "proceed_as_contractor|proceed_as_employee|escalate_to_lawyer",
        "full_analysis": {},
        "escalation_triggers": []
      }
    PROMPT
  end

  def default_output_template
    <<~PROMPT
      Generate a structured legal review output as JSON with:
      {
        "extracted_terms": {},
        "risk_scores": {},
        "overall_risk_score": 0-10,
        "summary": "",
        "negotiation_points": [],
        "recommended_action": "",
        "full_analysis": {},
        "escalation_triggers": []
      }
    PROMPT
  end

  # Prompt builders
  def build_initial_analysis_prompt
    <<~PROMPT
      Analyze the following #{review.domain_config[:name]} document for a content creator.

      Creator Context:
      #{review.creator_context.to_json}

      Document Text:
      ---
      #{review.document_text}
      ---

      Provide a thorough analysis identifying:
      1. All parties involved
      2. Material terms and conditions
      3. Risk areas and red flags
      4. Key findings
      5. Any terms that should trigger escalation to a human lawyer
    PROMPT
  end

  def build_legal_expert_prompt(analysis)
    <<~PROMPT
      Evaluate this legal analysis for accuracy and completeness:

      #{analysis.to_json}

      Original document excerpt (first 2000 chars):
      #{review.document_text[0..2000]}

      Provide your evaluation scores and feedback.
    PROMPT
  end

  def build_business_expert_prompt(analysis)
    <<~PROMPT
      Evaluate this legal analysis for business practicality:

      #{analysis.to_json}

      Creator Context:
      #{review.creator_context.to_json}

      Is this advice practical for a creator in this situation? Would a savvy creator manager give similar advice?
    PROMPT
  end

  def build_refinement_prompt(initial_analysis, evaluation)
    <<~PROMPT
      Your initial analysis received the following feedback:

      Legal Expert: #{evaluation[:legal_expert].to_json}
      Business Expert: #{evaluation[:business_expert].to_json}

      Original Analysis:
      #{initial_analysis.to_json}

      Please provide a refined analysis addressing the feedback while maintaining accuracy.
    PROMPT
  end

  def build_final_output_prompt(analysis)
    <<~PROMPT
      Based on this analysis, generate the final structured output:

      #{analysis.to_json}

      Creator Context:
      #{review.creator_context.to_json}

      Ensure the output is practical, clear, and actionable for the creator.
    PROMPT
  end

  def build_end_loop_evaluation_prompt(final_output)
    <<~PROMPT
      Evaluate this final legal review output:

      #{final_output.to_json}

      Original Document (excerpt):
      #{review.document_text[0..2000]}

      Score each dimension from 0-10 based on the evaluation criteria.
    PROMPT
  end

  # Response parsers
  def parse_structured_response(response)
    # Try to extract JSON from response
    json_match = response.match(/\{[\s\S]*\}/)
    return {} unless json_match

    JSON.parse(json_match[0])
  rescue JSON::ParserError
    { raw_response: response }
  end

  def parse_evaluation_response(evaluations)
    result = {}
    evaluations.each do |expert, response|
      parsed = parse_structured_response(response)
      result[expert] = parsed.is_a?(Hash) ? parsed.symbolize_keys : { raw: response, score: 3 }
    end
    result
  end

  def parse_final_output(response)
    parsed = parse_structured_response(response)
    return { error: 'Failed to parse output' } unless parsed.is_a?(Hash)

    {
      extracted_terms: parsed['extracted_terms'] || {},
      risk_scores: parsed['risk_scores'] || {},
      overall_risk_score: parsed['overall_risk_score'].to_f,
      summary: parsed['summary'] || '',
      negotiation_points: parsed['negotiation_points'] || [],
      recommended_action: normalize_action(parsed['recommended_action']),
      full_analysis: parsed,
      escalation_triggers: parsed['escalation_triggers'] || []
    }
  end

  def parse_scores(response)
    parsed = parse_structured_response(response)
    return default_scores unless parsed.is_a?(Hash)

    {
      'legal_accuracy' => parsed['legal_accuracy'].to_f,
      'business_practicality' => parsed['business_practicality'].to_f,
      'clarity' => parsed['clarity'].to_f,
      'completeness' => parsed['completeness'].to_f,
      'calibration' => parsed['calibration'].to_f
    }
  end

  def default_scores
    {
      'legal_accuracy' => 5.0,
      'business_practicality' => 5.0,
      'clarity' => 5.0,
      'completeness' => 5.0,
      'calibration' => 5.0
    }
  end

  def normalize_action(action)
    valid_actions = %w[sign_as_is negotiate escalate_to_lawyer walk_away]
    return action if valid_actions.include?(action)

    # Try to map common variations
    case action&.downcase
    when /sign/, /proceed/, /approve/
      'sign_as_is'
    when /negotiat/
      'negotiate'
    when /escalat/, /lawyer/, /attorney/, /consult/
      'escalate_to_lawyer'
    when /walk/, /decline/, /reject/
      'walk_away'
    else
      'negotiate' # Default to cautious action
    end
  end
end
