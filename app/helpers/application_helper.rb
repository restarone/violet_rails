module ApplicationHelper
  def display_subdomain_name(schema_path)
    "#{schema_path}.#{ENV['APP_HOST']}"
  end
end
