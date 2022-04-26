class ApiNamespace::Plugin::V1::SubdomainEventsService
  def initialize(object)
    @object = object
  end

  def track_event
    return if !Subdomain.current.api_plugin_events_enabled
    api_namespace = ApiNamespace.find_by(slug: ApiNamespace::REGISTERED_PLUGINS[:subdomain_events][:slug], version: ApiNamespace::REGISTERED_PLUGINS[:subdomain_events][:version])
    # to-do this should not be an issue. see https://github.com/restarone/violet_rails/issues/327
    normalized_props = api_namespace.properties.class == Hash ? api_namespace.properties : JSON.parse(api_namespace.properties)
    api_properties = normalized_props.deep_symbolize_keys    
    object_type = @object.class.to_s
    domain_with_fallback = Apartment::Tenant.current != 'public' ? Subdomain.current.name : Apartment::Tenant.current
    resource_properties = {
      model: {
        record_id: @object.id,
        record_type: object_type
      }
    }
    case object_type
    when 'Message'
      # to-do plug in validations, make sure the same message doesnt have 2 events created after it 
      resource_properties[:representation] = {
        body: "New Email @ #{domain_with_fallback}.#{ENV['APP_HOST']} - from: #{@object.from}"
      }
    when 'ForumThread'
      created_by_user = @object.user
      resource_properties[:representation] = {
        body: "New Forum Thread @ #{domain_with_fallback}.#{ENV['APP_HOST']} - created by: #{created_by_user.name} (#{created_by_user.email})"
      }
    when 'ForumPost'
      created_by_user = @object.user
      resource_properties[:representation] = {
        body: "New Forum Post @ #{domain_with_fallback}.#{ENV['APP_HOST']} - created by: #{created_by_user.name} (#{created_by_user.email})"
      }
    end
    ApiResourceSpawnJob.perform_async(api_namespace.id, resource_properties.to_json)
  end
end