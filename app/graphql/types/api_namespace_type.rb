# frozen_string_literal: true

module Types
  class ApiNamespaceType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :slug, String, null: false
    field :version, Integer, null: false
    field :properties, GraphQL::Types::JSON
    field :requires_authentication, Boolean
    field :namespace_type, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # {
    #   apiResources(limit: 3, orderDirection:"asc", orderDimension: "createdAt", offset: 1) {
    #     id
    #      properties
    #   }
    # }
    field :api_resources, [Types::ApiResourceType], null: true do
      description "Returns a list of ApiResources with ordering dimension, order direction, offset and limit"
      argument :limit, Integer, required: false
      argument :order_direction, String, required: false
      argument :order_dimension, String, required: false
      argument :offset, Integer, required: false
      argument :properties, GraphQL::Types::JSON, required: false

      def resolve(parent, frozen_parameters, context)
        parameters = { **frozen_parameters }
        parameters[:order_dimension] ||= 'created_at'
        parameters[:order_direction] ||= 'desc'
        parameters[:limit] ||= 50
        parameters[:offset] ||= 0

        api_resources = parent.object.api_resources
        api_resources = api_resources.jsonb_search(:properties, parameters[:properties]) if parameters[:properties]
        
        api_resources.order("#{parameters[:order_dimension].underscore} #{parameters[:order_direction]}").limit(parameters[:limit]).offset(parameters[:offset])
      end
    end
  end
end
