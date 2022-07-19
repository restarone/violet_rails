require "test_helper"

class BishopMonitoringPluginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_api: true)
  end

  test "#BishopMonitoring: sends HTTP request and does not log incident (resource creation + email) if HTTP endpoint error does not occur" do
    bishop_plugin = external_api_clients(:bishop_monitoring)
    api_namespace = api_namespaces(:monitoring_targets)
    bishop_request = stub_request(:get, api_namespace.api_resources.first.properties['url'])
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

  test "#BishopMonitoring: sends HTTP request and does log incident (resource creation) if HTTP endpoint error does occur" do
    bishop_plugin = external_api_clients(:bishop_monitoring)
    api_namespace = api_namespaces(:monitoring_targets)
    bishop_request = stub_request(:get, api_namespace.api_resources.first.properties['url'])
      .to_return(status: 500, body: "Gateway unavailable")

    sign_in(@user)
    # TODO: fix to ensure that only 1 API resource is created (https://github.com/restarone/violet_rails/issues/584)
    assert_changes 'ApiResource.count' do
      get start_api_namespace_external_api_client_path(api_namespace_id: api_namespace.id, id: bishop_plugin.id)
      Sidekiq::Worker.drain_all
    end
  end

  test "#BishopMonitoring: does log incident, send HTTP request and email if HTTP endpoint error occurs" do
    skip("# TODO: this should send the email, but we dont fire it from the model context (https://github.com/restarone/violet_rails/issues/584)")
    bishop_plugin = external_api_clients(:bishop_monitoring)
    api_namespace = api_namespaces(:monitoring_targets)
    bishop_request = stub_request(:get, api_namespace.api_resources.first.properties['url'])
      .to_return(status: 500, body: "Gateway unavailable")

    sign_in(@user)
    assert_changes "ApiActionMailer.deliveries.size" do          
      get start_api_namespace_external_api_client_path(api_namespace_id: api_namespace.id, id: bishop_plugin.id)
      Sidekiq::Worker.drain_all
    end
  end

end