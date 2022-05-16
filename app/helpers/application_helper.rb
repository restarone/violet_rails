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

    ApiAction::EXECUTION_ORDER.each do |action_type|
      if ApiAction.action_types[action_type] == ApiAction.action_types[:serve_file]
        handle_serve_file_action if @serve_file_action.present?
      elsif ApiAction.action_types[action_type] == ApiAction.action_types[:redirect]
        handle_redirection if @redirect_action.present?
      elsif ApiAction.action_types[action_type] == ApiAction.action_types[:custom_action]
        handle_custom_actions if @custom_actions.present?
      elsif ApiAction.action_types[action_type] == ApiAction.action_types[:send_email]
        api_actions.where(action_type: ApiAction.action_types[:send_email]).each do |send_email_action|
          send_email_action.execute_action
        end
      elsif ApiAction.action_types[action_type] == ApiAction.action_types[:send_web_request]
        api_actions.where(action_type: ApiAction.action_types[:send_web_request]).each do |send_web_request_action|
          send_web_request_action.execute_action
        end
      end
    end
    #api_actions.each do |api_action|
    #  api_action.execute_action unless api_action.serve_file? || api_action.redirect? || api_action.custom_action?
    #end
  end

  def file_id_from_snippet(file_snippet)
    ComfortableMexicanSofa::Content::Renderer.new(:page).tokenize(file_snippet).last[:tag_params]
  end
end
