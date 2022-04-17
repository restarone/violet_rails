# frozen_string_literal: true

module Types
  class ApiResourceType < Types::BaseObject
    field :id, ID, null: false
    field :api_namespace, Types::ApiNamespaceType, null: false
    field :api_namespace_id, ID, null: false
    field :properties, GraphQL::Types::JSON
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end


