require "test_helper"

class ApiNamespaceTest < ActiveSupport::TestCase
  setup do
    @subdomain = subdomains(:public)
    @subdomain.update(api_plugin_events_enabled: true)
    @subdomain_events_api = api_namespaces(:plugin_subdomain_events)
    @subdomain_events_api.api_resources.destroy_all
    @message_thread = message_threads(:public)
    @message = @message_thread.messages.create!(content: "Hello")
    Sidekiq::Testing.fake!
  end

  test "plugin: subdomain/subdomain_events -> tracks message creation by creating ApiResource" do
    service = SubdomainEventsService.new(@message)
    assert_difference "ApiResource.count", +1 do      
      service.track_event
      Sidekiq::Worker.drain_all
    end
    resource = @subdomain_events_api.api_resources.reload.last
    model =  resource.properties["model"]
    representation =  resource.properties["representation"]
    assert_equal ["model", "representation"].sort, resource.properties.keys.sort
    assert_equal ["record_id", "record_type"].sort, model.keys.sort
    assert_equal model["record_type"].constantize, Message
    assert model["record_type"].constantize.send(:find, model["record_id"])
    assert_equal representation["body"].class, String
  end

  test "plugin: subdomain/subdomain_events -> tracks message creation by creating ApiResource & running actions" do
    service = SubdomainEventsService.new(@message)
    assert_difference "ApiResource.count", +1 do      
      service.track_event
      Sidekiq::Worker.drain_all
    end
    assert_equal @subdomain_events_api.executed_api_actions.first.reload.lifecycle_stage, 'failed'
  end
end
