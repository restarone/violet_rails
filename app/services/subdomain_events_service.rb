class SubdomainEventsService
  def initialize(object)
    @object = object
  end

  def track_event
    return if !Subdomain.current.api_plugin_events_enabled
    api_namespace = ApiNamespace.find_by(slug: ApiNamespace::REGISTERED_PLUGINS[:subdomain_events][:slug])
    api_properties = JSON.parse(api_namespace.properties).deep_symbolize_keys    
    object_type = @object.class.to_s
    case object_type
    when 'Message'
      # to-do plug in validations, make sure the same message doesnt have 2 events created after it 
      representation = api_properties[:representations][:Message]
      resource_properties = {
        properties: {
          model: {
            record_id: @object.id,
            record_type: object_type
          },
          representation: {
            body: @object.content
          }
        }
      }
      ApiResourceSpawnJob.perform_async(api_namespace.id, resource_properties)
    end
    
  end
end