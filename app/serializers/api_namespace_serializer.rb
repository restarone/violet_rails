class ApiNamespaceSerializer
  include JSONAPI::Serializer
  attributes :id, :created_at, :updated_at, :properties, :version, :slug, :name, :namespace_type, :requires_authentication
end
