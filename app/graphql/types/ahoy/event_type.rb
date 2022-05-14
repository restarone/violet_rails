# frozen_string_literal: true

module Types
  class Ahoy::EventType < Types::BaseObject
    field :id, ID, null: false
    field :visit_id, Integer
    field :user_id, Integer
    field :name, String
    field :properties, GraphQL::Types::JSON
    field :time, GraphQL::Types::ISO8601DateTime
  end
end
