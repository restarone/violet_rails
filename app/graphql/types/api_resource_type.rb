# frozen_string_literal: true

module Types
  class ApiResourceType < Types::BaseObject
    field :id, ID, null: false
    field :api_namespace, Types::ApiNamespaceType, null: false
    field :api_namespace_id, ID, null: false
    field :properties, GraphQL::Types::JSON
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # {
    #   nonPrimitiveProperties {
    #     id
    #     label
    #   }
    # }
    field :non_primitive_properties, [Types::NonPrimitivePropertyType], null: true do
      description "Returns a list of NonPrimitiveProperties"

      def resolve(parent, frozen_parameters, context)
        parent.object.non_primitive_properties
      end
    end
  end
end


