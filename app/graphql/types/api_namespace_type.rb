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
    field :api_resources, [Types::ApiResourceType], null: false
  end
end
