module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # the field below maps like this. Snake case to camelcase
    # {
    #   apiNamespaces(limit: 3, orderDirection:"asc", orderDimension: "created_at", offset: 1) {
    #     id
    #     slug
    #     properties
    #     apiResources {
    #       id
    #       properties
    #     }
    #   }
    # }
    field :api_namespaces, [Types::ApiNamespaceType], null: false do
      description "Returns a list of public ApiNamespaces with ordering dimension, order direction, offset and limit"
      argument :limit, Integer, required: false
      argument :order_direction, String, required: false
      argument :order_dimension, String, required: false
      argument :offset, Integer, required: false
      argument :slug, String, required: false
    end

    # {
    #   ahoyVisits(limit: 100,orderDirection:"desc", orderDimension: "started_at") {
    #     id
    #     ip
    #     userAgent
    #     referringDomain
    #     landingPage
    #     country
    #     city
    #     platform
    #     events {
    #       id
    #       visitId
    #       userId
    #       name
    #       properties
    #     }
    #   }
    # }
    field :ahoy_visits, [Types::Ahoy::VisitsType], null: false do
      description "Returns a list of ahoy visits"
      argument :limit, Integer, required: false
      argument :order_direction, String, required: false
      argument :order_dimension, String, required: false
      argument :offset, Integer, required: false
    end
    # {
    #   ahoyEvents(limit: 100, orderDirection:"desc", orderDimension: "time", name: "comfy-cms-page-visit") {
    #     id
    #     visitId
    #     name
    #     properties
    #     time
    #   }
    # }
    field :ahoy_events, [Types::Ahoy::EventsType], null: false do
      description "Returns a list of ahoy events"
      argument :limit, Integer, required: false
      argument :order_direction, String, required: false
      argument :order_dimension, String, required: false
      argument :offset, Integer, required: false

      argument :name, String, required: false
    end
    # {
    #   ahoyEventNames {
    #     name
    #   }
    # }
    field :ahoy_event_names, [Types::Ahoy::EventNamesType], null: false do
      description "Returns all the ahoy event names that are being used in the system"
    end
    
    def api_namespaces(args = {})
      args[:order_dimension] ||= 'created_at'
      args[:order_direction] ||= 'desc'
      args[:limit] ||= 50
      args[:offset] ||= 0
      args[:slug] ||= nil
      if args[:slug]
        return ApiNamespace.where(requires_authentication: false, slug: args[:slug]).order("#{args[:order_dimension].underscore} #{args[:order_direction]}").limit(args[:limit]).offset(args[:offset])
      else
        return ApiNamespace.where(requires_authentication: false).order("#{args[:order_dimension].underscore} #{args[:order_direction]}").limit(args[:limit]).offset(args[:offset])
      end
    end

    def ahoy_visits(args = {})
      args[:order_dimension] ||= 'started_at'
      args[:order_direction] ||= 'desc'
      args[:limit] ||= 50
      args[:offset] ||= 0
      # the trailing :: is required to look for this namespace at the top level instead of in Types:: 
      return ::Ahoy::Visit.all.includes(:events).order("#{args[:order_dimension].underscore} #{args[:order_direction]}").limit(args[:limit]).offset(args[:offset])
    end

    def ahoy_events(args = {})
      args[:order_dimension] ||= 'time'
      args[:order_direction] ||= 'desc'
      args[:limit] ||= 50
      args[:offset] ||= 0
      if args[:name]
        return ::Ahoy::Event.where(name: args[:name]).order("#{args[:order_dimension].underscore} #{args[:order_direction]}").limit(args[:limit]).offset(args[:offset])
      else
        return ::Ahoy::Event.all.order("#{args[:order_dimension].underscore} #{args[:order_direction]}").limit(args[:limit]).offset(args[:offset])
      end
    end

    def ahoy_event_names
      return ::Ahoy::Event.distinct.pluck(:name).map{|name| {name: name} }
    end
  end
end

