module ApplicationHelper
  def display_subdomain_name(schema_path)
    subdomain = schema_path != Subdomain::ROOT_DOMAIN_NAME ? schema_path : 'www'
    "#{subdomain}.#{ENV['APP_HOST']}"
  end

  def page_entries_info(collection)
    model_name = collection.respond_to?(:human_name) ? collection.model_name.human : (collection.first&.model_name&.human || '')

    sanitize "Displaying #{model_name} " +
      tag.b("#{collection.offset + 1} - #{[collection.per_page * collection.current_page, collection.total_entries].min}") +
      ' of ' + tag.b(collection.total_entries) +
      ' in total'
  end

  def execute_actions(resource, class_name)
    api_actions = resource.send(class_name)
    api_actions.each do |api_action|
      api_action.execute_action unless api_action.serve_file? || api_action.redirect?
    end
  end

  def file_id_from_snippet(file_snippet)
    ComfortableMexicanSofa::Content::Renderer.new(:page).tokenize(file_snippet).last[:tag_params]
  end

  # Action name supports only alphanumeric characters, underscores and slash(/)
  # reference: https://developers.google.com/recaptcha/docs/faq#what-action-names-are-valid
  def sanitize_recaptcha_action_name(action_name)
    action_name.strip.gsub(/[- ]/, '_').scan(/[\/\_a-zA-Z0-9]/).join
  end
end
