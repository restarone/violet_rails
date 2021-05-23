module ApplicationHelper
  def display_subdomain_name(schema_path)
    "#{schema_path}.#{ENV['APP_HOST']}"
  end

  def page_entries_info(collection)
    model_name = collection.respond_to?(:human_name) ? collection.model_name.human : (collection.first&.model_name&.human || '')

    sanitize "Displaying #{model_name} " +
      tag.b("#{collection.offset + 1} - #{[collection.per_page * collection.current_page, collection.total_entries].min}") +
      ' of ' + tag.b(collection.total_entries) +
      ' in total'
end
end
