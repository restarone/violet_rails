# frozen_string_literal: true

module Types
    class NonPrimitivePropertyType < Types::BaseObject
      field :id, ID, null: false
      field :api_resource, Types::ApiResourceType, null: false
      field :api_resource_id, ID, null: false
      field :field_type, String
      field :label, String
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
      field :url, String
      field :content, String
      field :mime_type, String

      def url
        object.file_url if object.file?
      end

      def content
        object.content.body if object.richtext?
      end

      def mime_type
        object.attachment.content_type if object.file?
      end
    end
  end
  