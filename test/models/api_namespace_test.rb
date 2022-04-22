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
      assert_changes "@subdomain_events_api.create_api_actions.first.lifecycle_stage" do        
        service.track_event
        Sidekiq::Worker.drain_all
      end
    end
    @subdomain_events_api.api_resources.reload.last.properties
  end

  test "plugin: subdomain/subdomain_events -> tracks message creation by creating ApiResource & running actions" do
    skip('investigate why api_resource_id: is not set on the @subdomain_events_api.create_api_actions.first')
    service = SubdomainEventsService.new(@message)
    assert_difference "ApiResource.count", +1 do      
      assert_changes "@subdomain_events_api.create_api_actions.first.lifecycle_stage" do        
        service.track_event
        Sidekiq::Worker.drain_all
      end
    end
    # byebug
    assert_not_equal @subdomain_events_api.create_api_actions.first.lifecycle_stage, 'failed'
  end
end
