# frozen_string_literal: true

module Types
  class Ahoy::VisitsType < Types::BaseObject
    field :id, ID, null: false
    field :visit_token, String
    field :visitor_token, String
    field :user_id, Integer
    field :ip, String
    field :user_agent, String
    field :referrer, String
    field :referring_domain, String
    field :landing_page, String
    field :browser, String
    field :os, String
    field :device_type, String
    field :country, String
    field :region, String
    field :city, String
    field :latitude, Float
    field :longitude, Float
    field :utm_source, String
    field :utm_medium, String
    field :utm_term, String
    field :utm_content, String
    field :utm_campaign, String
    field :app_version, String
    field :os_version, String
    field :platform, String
    field :started_at, GraphQL::Types::ISO8601DateTime
  end
end
