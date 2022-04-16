module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # the field below maps like this. Snake case to camelcase
    # {
    #   apiNamespaces {
    #     id
    #   }
    # }
    field :api_namespaces, 
    [Types::ApiNamespaceType], 
    null: false,
    description: "Returns a list of ApiNamespaces"

    # {
    #   apiResources {
    #     id
    #   }
    # }
    field :api_resources, 
    [Types::ApiResourceType], 
    null: true,
    description: "Returns a list of ApiResources"

    def api_namespaces
      ApiNamespace.all
    end

    def api_resources
      ApiResource.all
    end
  end
end

