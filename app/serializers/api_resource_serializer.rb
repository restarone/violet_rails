class ApiResourceSerializer
  include JSONAPI::Serializer
  attributes :id, :created_at, :updated_at, :properties
end
