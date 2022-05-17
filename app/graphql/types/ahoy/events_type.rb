# frozen_string_literal: true

module Types
  class Ahoy::EventsType < Types::BaseObject
    field :id, ID, null: false
    field :visit_id, Integer
    field :user_id, Integer
    field :name, String
    field :properties, GraphQL::Types::JSON
    field :time, GraphQL::Types::ISO8601DateTime

    def self.authorized?(object, context)
      if Subdomain.current.allow_external_analytics_query
        return true
      end
      return false
    end
  end
end
