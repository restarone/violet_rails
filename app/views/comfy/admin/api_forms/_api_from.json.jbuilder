json.extract! api_form, :id, :api_namespace_id, :properties, :created_at, :updated_at, :title, :success_message, :error_message
json.url api_form_url(api_form, format: :json)
