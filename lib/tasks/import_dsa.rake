# lib/tasks/import_dsa.rake
# Task to import DSA algorithms into Violet Rails

namespace :dsa do
  desc "Import DSA algorithms from dsa-seed-data.rb"
  task import: :environment do
    puts "Loading DSA seed data..."
    require_relative '../../dsa-seed-data'

    puts "\nImporting #{ALGORITHMS.length} algorithms..."
    puts "=" * 60

    # Switch to the correct subdomain/tenant
    # You'll need to update this with your actual subdomain name
    subdomain_name = 'dsa'  # or ENV['SUBDOMAIN'] for flexibility

    begin
      Apartment::Tenant.switch!(subdomain_name)
      puts "Switched to subdomain: #{subdomain_name}"
    rescue Apartment::TenantNotFound
      puts "Subdomain '#{subdomain_name}' not found. Please create it first via /signup_wizard"
      exit 1
    end

    # Find or create the API Namespace for algorithms
    api_namespace = ApiNamespace.find_or_create_by!(
      name: 'algorithms',
      namespace_type: 'show',
      version: 1
    ) do |ns|
      ns.properties = build_algorithm_properties
    end

    puts "API Namespace 'algorithms' ready (ID: #{api_namespace.id})"
    puts "\nImporting algorithms..."

    success_count = 0
    error_count = 0

    ALGORITHMS.each_with_index do |algorithm_data, index|
      begin
        algorithm = api_namespace.api_resources.find_or_initialize_by(
          properties: { 'problem_number' => algorithm_data[:problem_number] }
        )

        algorithm.properties = algorithm_data.transform_keys(&:to_s)
        algorithm.properties['production_status'] = 'Not Started'  # Default status
        algorithm.properties['created_at'] = Time.current.to_s unless algorithm.persisted?
        algorithm.properties['updated_at'] = Time.current.to_s

        if algorithm.save
          success_count += 1
          print "."
        else
          error_count += 1
          puts "\nError saving #{algorithm_data[:name]}: #{algorithm.errors.full_messages.join(', ')}"
        end

        # Progress indicator every 10 algorithms
        if (index + 1) % 10 == 0
          puts " [#{index + 1}/#{ALGORITHMS.length}]"
        end
      rescue StandardError => e
        error_count += 1
        puts "\nException importing #{algorithm_data[:name]}: #{e.message}"
      end
    end

    puts "\n\n" + "=" * 60
    puts "Import Complete!"
    puts "Successfully imported: #{success_count} algorithms"
    puts "Errors: #{error_count}" if error_count > 0
    puts "=" * 60

    # Summary by phase
    puts "\nAlgorithms by Learning Phase:"
    (1..7).each do |phase|
      count = ApiResource.where("properties->>'learning_phase' = ?", phase.to_s).count
      phase_name = LEARNING_PHASES.find { |p| p[:phase_number] == phase }[:name]
      puts "  Phase #{phase} (#{phase_name}): #{count} algorithms"
    end

    puts "\nAlgorithms by Difficulty:"
    %w[Easy Medium Hard].each do |difficulty|
      count = ApiResource.where("properties->>'difficulty' = ?", difficulty).count
      puts "  #{difficulty}: #{count} algorithms"
    end

    puts "\nNext steps:"
    puts "1. Visit http://#{subdomain_name}.localhost:5250/admin"
    puts "2. Navigate to API Resources → algorithms"
    puts "3. View and manage your DSA directory"
    puts "\n"
  end

  def build_algorithm_properties
    {
      'name' => { 'field_type' => 'string', 'label' => 'Algorithm Name' },
      'problem_number' => { 'field_type' => 'number', 'label' => 'Problem Number' },
      'difficulty' => { 'field_type' => 'string', 'label' => 'Difficulty' },
      'priority' => { 'field_type' => 'number', 'label' => 'Priority' },
      'primary_data_structure' => { 'field_type' => 'string', 'label' => 'Primary Data Structure' },
      'time_complexity' => { 'field_type' => 'string', 'label' => 'Time Complexity' },
      'space_complexity' => { 'field_type' => 'string', 'label' => 'Space Complexity' },
      'prerequisites' => { 'field_type' => 'text', 'label' => 'Prerequisites' },
      'visual_complexity' => { 'field_type' => 'string', 'label' => 'Visual Complexity' },
      'recommended_medium' => { 'field_type' => 'string', 'label' => 'Recommended Medium' },
      'estimated_production_time' => { 'field_type' => 'string', 'label' => 'Estimated Production Time' },
      'key_visual_elements' => { 'field_type' => 'text', 'label' => 'Key Visual Elements' },
      'cognitive_load' => { 'field_type' => 'string', 'label' => 'Cognitive Load' },
      'real_world_analogy' => { 'field_type' => 'string', 'label' => 'Real World Analogy' },
      'learning_domain' => { 'field_type' => 'string', 'label' => 'Learning Domain' },
      'learning_phase' => { 'field_type' => 'number', 'label' => 'Learning Phase (1-7)' },
      'problem_hook_title' => { 'field_type' => 'string', 'label' => 'Problem Hook Title' },
      'problem_hook_analogy' => { 'field_type' => 'text', 'label' => 'Problem Hook Analogy' },
      'learning_objective' => { 'field_type' => 'text', 'label' => 'Learning Objective' },
      'key_insights' => { 'field_type' => 'text', 'label' => 'Key Insights' },
      'practice_challenge' => { 'field_type' => 'text', 'label' => 'Practice Challenge' },
      'related_algorithms' => { 'field_type' => 'text', 'label' => 'Related Algorithms' },
      'walkthrough_content' => { 'field_type' => 'richtext', 'label' => 'Algorithm Walkthrough' },
      'production_status' => { 'field_type' => 'string', 'label' => 'Production Status' },
      'visual_url' => { 'field_type' => 'string', 'label' => 'Visual/Animation URL' }
    }
  end
end
