json.extract! api_namespace, :id, :name, :version, :properties, :requires_authentication, :namespace_type, :created_at, :updated_at
json.url api_namespace_url(api_namespace, format: :json)
