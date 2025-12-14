module CreatorLegalReview
  # Comprehensive Benchmark Test Suite for Creator Legal Review Agent
  # Based on the Domain-Driven Development specification
  #
  # This module provides test cases for validating the AI analysis quality
  # across all five domains: Brand Deals, MCN Negotiations, Business Formation,
  # Merchandise, and Team Hires.
  module BenchmarkTestSuite
    BRAND_DEAL_TEST_CASES = [
      {
        id: 'BD-001',
        scenario: 'Standard sponsorship with predatory terms',
        key_challenge: 'Perpetual rights, broad exclusivity',
        expected_risk: 'high',
        input: {
          contract_text: <<~CONTRACT,
            INFLUENCER MARKETING AGREEMENT

            This Agreement is entered into by Brand Corp ("Brand") and Creator ("Influencer").

            1. DELIVERABLES: Influencer agrees to create and publish:
               - Three (3) Instagram feed posts
               - Five (5) Instagram stories
               - Content must be posted within 14 days of brief approval

            2. COMPENSATION: Brand shall pay Influencer a flat fee of $5,000 USD.
               Payment shall be made within Net-60 days of content approval.

            3. USAGE RIGHTS: Influencer grants Brand a perpetual, worldwide, royalty-free,
               sublicensable license to use, reproduce, modify, adapt, publish, translate,
               create derivative works from, distribute, and display the Content in any
               and all media formats and channels now known or later developed.

            4. EXCLUSIVITY: During the Campaign Period and for twelve (12) months following,
               Influencer shall not promote, endorse, or create content for any competing
               products in the fitness and wellness category.

            5. TERMINATION: Brand may terminate this Agreement at any time for any reason.
               Upon termination, Influencer shall not be entitled to any unpaid compensation.
          CONTRACT
          creator_context: {
            follower_count: 250000,
            platform: 'Instagram',
            niche: 'Fitness',
            previous_deals: 5
          }
        },
        expected_output: {
          risk_scores: {
            compensation: { min: 5, max: 7 }, # Below market, Net-60 is slow
            usage_rights: { min: 8, max: 10 }, # Perpetual is predatory
            exclusivity: { min: 7, max: 10 }, # 12 months post-campaign excessive
            termination: { min: 8, max: 10 } # Unilateral, no kill fee
          },
          overall_risk: { min: 7, max: 10 },
          recommended_action: 'negotiate',
          must_identify: [
            'perpetual license',
            'broad exclusivity',
            'unilateral termination',
            'no kill fee',
            'below market rate'
          ]
        },
        evaluation_rubric: {
          legal_accuracy: 'All 5 material terms correctly identified',
          business_practicality: 'Correctly identified as below market for 250K followers',
          clarity: 'Plain English explanation of perpetual rights implications'
        }
      },
      {
        id: 'BD-002',
        scenario: 'Fair deal, minor improvements possible',
        key_challenge: 'Usage scope slightly broad',
        expected_risk: 'low',
        input: {
          contract_text: <<~CONTRACT,
            BRAND PARTNERSHIP AGREEMENT

            1. DELIVERABLES: Creator will produce two (2) YouTube videos.
            2. COMPENSATION: $15,000 USD, paid 50% upfront, 50% upon delivery.
            3. USAGE: Brand may use content on owned social channels for 6 months.
            4. EXCLUSIVITY: Category exclusivity during campaign (2 weeks) only.
            5. TERMINATION: Either party may terminate with 14 days notice.
               Creator entitled to payment for work completed.
          CONTRACT
          creator_context: {
            follower_count: 500000,
            platform: 'YouTube',
            niche: 'Tech',
            previous_deals: 20
          }
        },
        expected_output: {
          overall_risk: { min: 1, max: 4 },
          recommended_action: 'sign_as_is'
        }
      },
      {
        id: 'BD-003',
        scenario: 'Complex multi-platform campaign',
        key_challenge: 'Multiple deliverable types, phased payment',
        expected_risk: 'medium'
      },
      {
        id: 'BD-004',
        scenario: 'UGC whitelisting agreement',
        key_challenge: 'Paid media rights, no base fee',
        expected_risk: 'medium_high'
      },
      {
        id: 'BD-005',
        scenario: 'Affiliate-only deal',
        key_challenge: 'Commission structure, no guaranteed payment',
        expected_risk: 'medium'
      },
      {
        id: 'BD-006',
        scenario: 'Ambassador long-term contract',
        key_challenge: '12-month commitment, equity component',
        expected_risk: 'medium'
      },
      {
        id: 'BD-007',
        scenario: 'International brand, foreign law',
        key_challenge: 'Governing law in UK, US creator',
        expected_risk: 'high'
      },
      {
        id: 'BD-008',
        scenario: 'Startup equity deal',
        key_challenge: 'Payment in stock, vesting schedule',
        expected_risk: 'high'
      }
    ].freeze

    MCN_TEST_CASES = [
      {
        id: 'MCN-001',
        scenario: 'Major MCN, standard terms',
        key_challenge: '70/30 split, 3-year term',
        expected_risk: 'medium',
        expected_recommendation: 'negotiate'
      },
      {
        id: 'MCN-002',
        scenario: 'Small MCN, aggressive terms',
        key_challenge: 'Takes % of all revenue, 5-year term',
        expected_risk: 'high',
        expected_recommendation: 'walk_away'
      },
      {
        id: 'MCN-003',
        scenario: 'Fair deal, good reputation',
        key_challenge: '80/20 split, services guaranteed',
        expected_risk: 'low',
        expected_recommendation: 'sign_as_is'
      },
      {
        id: 'MCN-004',
        scenario: 'Escape existing bad MCN',
        key_challenge: 'Trapped in unfavorable contract',
        expected_risk: 'high',
        expected_recommendation: 'escalate_to_lawyer'
      },
      {
        id: 'MCN-005',
        scenario: 'MCN offering equity',
        key_challenge: 'Revenue share + company stock',
        expected_risk: 'high',
        expected_recommendation: 'escalate_to_lawyer'
      }
    ].freeze

    BUSINESS_FORMATION_TEST_CASES = [
      {
        id: 'BF-001',
        scenario: 'New creator, $30K/year',
        key_variables: 'Solo, no employees, digital only',
        expected_recommendation: 'single_member_llc'
      },
      {
        id: 'BF-002',
        scenario: 'Growing creator, $150K/year',
        key_variables: 'Solo, uses contractors',
        expected_recommendation: 's_corp_election'
      },
      {
        id: 'BF-003',
        scenario: 'Creator duo, 50/50',
        key_variables: 'Two owners, shared revenue',
        expected_recommendation: 'multi_member_llc'
      },
      {
        id: 'BF-004',
        scenario: 'Creator with merch',
        key_variables: 'Physical products, inventory',
        expected_recommendation: 'llc_plus_insurance'
      },
      {
        id: 'BF-005',
        scenario: 'Multi-state creator',
        key_variables: 'Lives in CA, travels for content',
        expected_recommendation: 'consult_for_state_selection'
      },
      {
        id: 'BF-006',
        scenario: 'Creator with employees',
        key_variables: '3 W-2 employees',
        expected_recommendation: 's_corp'
      }
    ].freeze

    MERCHANDISE_TEST_CASES = [
      {
        id: 'MR-001',
        scenario: 'T-shirt line, POD',
        key_variables: 'Apparel, print-on-demand',
        key_legal_issues: ['Trademark', 'Labeling']
      },
      {
        id: 'MR-002',
        scenario: 'Signature product collab',
        key_variables: 'Licensing deal with brand',
        key_legal_issues: ['IP ownership', 'Revenue share']
      },
      {
        id: 'MR-003',
        scenario: 'Supplements/vitamins',
        key_variables: 'Consumable, FDA regulated',
        key_legal_issues: ['Heavy compliance']
      },
      {
        id: 'MR-004',
        scenario: 'Kids products',
        key_variables: "Children's items",
        key_legal_issues: ['CPSIA', 'Testing']
      },
      {
        id: 'MR-005',
        scenario: 'Digital products',
        key_variables: 'Courses, templates',
        key_legal_issues: ['Terms of use', 'Refund policy']
      },
      {
        id: 'MR-006',
        scenario: 'International shipping',
        key_variables: 'Physical goods, worldwide',
        key_legal_issues: ['Import/export', 'Taxes']
      }
    ].freeze

    TEAM_HIRE_TEST_CASES = [
      {
        id: 'TH-001',
        scenario: 'Freelance editor',
        key_variables: 'Project-based, own equipment',
        key_legal_issues: ['Contractor agreement', 'IP'],
        expected_classification: 'independent_contractor'
      },
      {
        id: 'TH-002',
        scenario: 'Full-time manager',
        key_variables: '40 hrs/week, exclusive',
        key_legal_issues: ['Employee classification'],
        expected_classification: 'employee'
      },
      {
        id: 'TH-003',
        scenario: 'Friend as assistant',
        key_variables: 'Blurred lines, equity ask',
        key_legal_issues: ['Classification', 'Equity'],
        expected_recommendation: 'escalate_to_lawyer'
      },
      {
        id: 'TH-004',
        scenario: 'Overseas contractor',
        key_variables: 'International worker',
        key_legal_issues: ['Tax treaties', 'IP']
      },
      {
        id: 'TH-005',
        scenario: 'Converting contractor to employee',
        key_variables: 'Long-term contractor',
        key_legal_issues: ['Back taxes', 'Reclassification']
      },
      {
        id: 'TH-006',
        scenario: 'Firing a friend',
        key_variables: 'Need to terminate',
        key_legal_issues: ['Relationship', 'Legal']
      }
    ].freeze

    # Acceptance thresholds for quality scores
    ACCEPTANCE_THRESHOLDS = {
      production_ready: 8.0,
      acceptable_with_review: 7.0,
      needs_improvement: 6.0
    }.freeze

    # Evaluation dimension weights
    EVALUATION_WEIGHTS = {
      legal_accuracy: 0.30,
      business_practicality: 0.25,
      clarity: 0.20,
      completeness: 0.15,
      calibration: 0.10
    }.freeze

    class << self
      def all_test_cases
        {
          brand_deals: BRAND_DEAL_TEST_CASES,
          mcn_negotiations: MCN_TEST_CASES,
          business_formation: BUSINESS_FORMATION_TEST_CASES,
          merchandise: MERCHANDISE_TEST_CASES,
          team_hires: TEAM_HIRE_TEST_CASES
        }
      end

      def test_cases_for_domain(domain)
        case domain.to_sym
        when :brand_deal then BRAND_DEAL_TEST_CASES
        when :mcn_negotiation then MCN_TEST_CASES
        when :business_formation then BUSINESS_FORMATION_TEST_CASES
        when :merchandise then MERCHANDISE_TEST_CASES
        when :team_hire then TEAM_HIRE_TEST_CASES
        else []
        end
      end

      def total_test_count
        all_test_cases.values.flatten.count
      end

      def validate_result(test_case, result)
        validations = []

        # Validate risk score range
        if test_case[:expected_output]&.dig(:overall_risk)
          range = test_case[:expected_output][:overall_risk]
          actual = result[:overall_risk_score].to_f
          validations << {
            check: 'overall_risk_in_range',
            passed: actual >= range[:min] && actual <= range[:max],
            expected: "#{range[:min]}-#{range[:max]}",
            actual: actual
          }
        end

        # Validate recommended action
        if test_case[:expected_output]&.dig(:recommended_action)
          expected = test_case[:expected_output][:recommended_action]
          actual = result[:recommended_action]
          validations << {
            check: 'recommended_action',
            passed: actual == expected,
            expected: expected,
            actual: actual
          }
        end

        # Validate must-identify items
        if test_case[:expected_output]&.dig(:must_identify)
          must_identify = test_case[:expected_output][:must_identify]
          identified = result[:extracted_terms].to_s.downcase + result[:analysis_result].to_s.downcase
          must_identify.each do |item|
            validations << {
              check: "identifies_#{item.parameterize.underscore}",
              passed: identified.include?(item.downcase),
              expected: item,
              actual: identified.include?(item.downcase) ? 'found' : 'not found'
            }
          end
        end

        {
          test_case_id: test_case[:id],
          validations: validations,
          passed: validations.all? { |v| v[:passed] },
          pass_rate: validations.count { |v| v[:passed] }.to_f / validations.count
        }
      end

      def calculate_composite_score(evaluation_scores)
        EVALUATION_WEIGHTS.sum do |dimension, weight|
          (evaluation_scores[dimension.to_s].to_f * weight)
        end.round(2)
      end

      def quality_status(composite_score)
        return 'production_ready' if composite_score >= ACCEPTANCE_THRESHOLDS[:production_ready]
        return 'acceptable_with_review' if composite_score >= ACCEPTANCE_THRESHOLDS[:acceptable_with_review]
        return 'needs_improvement' if composite_score >= ACCEPTANCE_THRESHOLDS[:needs_improvement]
        'not_acceptable'
      end
    end
  end
end
