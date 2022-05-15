# frozen_string_literal: true

module Types
  class Ahoy::EventNamesType < Types::BaseObject

    field :name, String

    def self.authorized?(object, context)
      if Subdomain.current.allow_external_analytics_query
        return true
      end
      return false
    end
  end
end
