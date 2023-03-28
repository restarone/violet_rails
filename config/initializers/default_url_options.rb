module ActionDispatch::Routing
  module RouteSetExtensions
    # This allows lambdas as subdomain parameter for `default_url_options`:
    #
    #    Rails.application.routes.default_url_options = {
    #      host: 'example.com',
    #      protocol: 'https',
    #      subdomain: lambda { ... }
    #    }
    #
    def url_for(options, route_name = nil, url_strategy = ActionDispatch::Routing::RouteSet::UNKNOWN, method_name = nil, reserved = ActionDispatch::Routing::RouteSet::RESERVED_OPTIONS)
      if Rails.application.routes.default_url_options[:subdomain].respond_to? :call
        options[:subdomain] ||= Rails.application.routes.default_url_options[:subdomain].call
      end

      super(options, route_name, url_strategy, reserved)
    end
  end

  class RouteSet
    prepend RouteSetExtensions
  end
end

Rails.application.routes.default_url_options = {
  host: ENV['APP_HOST'],
  subdomain: lambda { Apartment::Tenant.current != 'public' ? Apartment::Tenant.current : '' },
  protocol: (Rails.env.production? || Rails.env.staging?) ? 'https': 'http'
}