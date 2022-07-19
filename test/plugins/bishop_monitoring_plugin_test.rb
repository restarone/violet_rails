require "test_helper"

class BishopMonitoringPluginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_api: true)
  end

  test "#BishopMonitoring: does not log incident (send HTTP request + email) if HTTP endpoint error does not occur" do
    bishop_plugin = external_api_clients(:bishop_monitoring)
    api_namespace = api_namespaces(:monitoring_targets)
    mailchimp_request = stub_request(:get, api_namespace.api_resources.first.properties['url'])
      .to_return(status: 200, body: "OK")

    sign_in(@user)
    perform_enqueued_jobs do
      assert_no_difference 'ApiResource.count' do
        assert_no_difference "ApiActionMailer.deliveries.size" do          
          get start_api_namespace_external_api_client_path(api_namespace_id: api_namespace.id, id: bishop_plugin.id)
          Sidekiq::Worker.drain_all
        end
      end
    end
  end

  test "#BishopMonitoring: does log incident, send HTTP request and email if HTTP endpoint error occurs" do
    bishop_plugin = external_api_clients(:bishop_monitoring)
    api_namespace = api_namespaces(:monitoring_targets)
    mailchimp_request = stub_request(:get, api_namespace.api_resources.first.properties['url'])
      .to_return(status: 500, body: "Gateway unavailable")

    sign_in(@user)
    assert_difference 'ApiResource.count', +1 do
      assert_difference "ApiActionMailer.deliveries.size", +1 do          
        get start_api_namespace_external_api_client_path(api_namespace_id: api_namespace.id, id: bishop_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end
  end

end