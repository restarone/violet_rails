class ApiResourceSerializer
  include JSONAPI::Serializer
  attributes :id, :created_at, :updated_at, :properties

  attribute :non_primitive_properties do |object|
    NonPrimitivePropertySerializer.new(object.non_primitive_properties).serializable_hash[:data]
  end
end
