require "test_helper"

class BishopTlsMonitoringPluginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
    WebMock.allow_net_connect!(net_http_connect_on_start: true)
  end

  test "#BishopTlsMonitoring: does not send HTTP request and email (api-actions) when HTTPS endpoint TLS certificate does not expire within 2 weeks" do
    Net::HTTP.any_instance.stubs(:peer_cert).returns(stub(:not_after => (Time.now + 2.months)))

    bishop_tls_plugin = external_api_clients(:bishop_tls_monitoring)
    api_namespace = api_namespaces(:tls_monitoring_targets)
    bishop_request = stub_request(:get, api_namespace.api_resources.first.properties['url'])
      .to_return(status: 200, body: "OK")

    sign_in(@user)
    perform_enqueued_jobs do
      assert_no_difference 'ApiResource.count' do
        assert_no_difference "ApiActionMailer.deliveries.size" do          
          get start_api_namespace_external_api_client_path(api_namespace_id: api_namespace.id, id: bishop_tls_plugin.id)
          Sidekiq::Worker.drain_all
        end
      end
    end
  end

  test "#BishopTlsMonitoring: does log incident, send HTTP request and email if HTTP endpoint has TLS certificate expiry within 2 weeks" do
    Net::HTTP.any_instance.stubs(:peer_cert).returns(stub(:not_after => (Time.now + 1.weeks)))

    bishop_tls_plugin = external_api_clients(:bishop_tls_monitoring)
    api_namespace = api_namespaces(:tls_monitoring_targets)
    bishop_request = stub_request(:get, api_namespace.api_resources.first.properties['url'])
      .to_return(status: 200, body: "OK")

    api_actions(:create_api_action_plugin_bishop_monitoring_web_request).update!(
      payload_mapping: { 'content': 'test body'},
      custom_headers: { 'accept': 'application/json'},
      bearer_token: 'TEST',
      request_url: 'http://www.discord.com',
      http_method: 'post'
    )
    
    target_namespace = api_namespaces(:monitoring_target_incident)
    discord_request = stub_request(:post, "http://www.discord.com").to_return(status: 200, body: 'Success.')

    sign_in(@user)
    
    # ActiveRecords will be created times the defined max-retries of plugin
    assert_difference 'ApiResource.count', +(1 * bishop_tls_plugin.max_retries)  do
      assert_difference 'ApiAction.count', +(target_namespace.create_api_actions.count * bishop_tls_plugin.max_retries) do
        # 1 send-email (times the defined max-retries of plugin) create-api-action is executed
        assert_difference "ActionMailer::Base.deliveries.count", +(1 * bishop_tls_plugin.max_retries) do
          get start_api_namespace_external_api_client_path(api_namespace_id: api_namespace.id, id: bishop_tls_plugin.id)
          Sidekiq::Worker.drain_all
        end
      end
    end

    assert_requested discord_request
  end
  
end