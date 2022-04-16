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
    #   apiResources(limit: 3, orderDirection:"asc", orderDimension: "created_at", offset: 1) {
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
    end

    def api_resources(args = {})
      args[:order_dimension] ||= 'created_at'
      args[:order_direction] ||= 'desc'
      args[:limit] ||= 50
      args[:offset] ||= 0
      ApiResource.all.order("#{args[:order_dimension]} #{args[:order_direction]}").limit(args[:limit]).offset(args[:offset])
    end
  end
end
