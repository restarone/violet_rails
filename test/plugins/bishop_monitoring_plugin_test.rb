require "test_helper"

class BishopMonitoringPluginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
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
    # ApiResources will be created times the defined max-retries of plugin
    assert_difference 'ApiResource.count', +(1 * bishop_plugin.max_retries)  do
      get start_api_namespace_external_api_client_path(api_namespace_id: api_namespace.id, id: bishop_plugin.id)
      Sidekiq::Worker.drain_all
    end
  end

  test "#BishopMonitoring: does log incident, send HTTP request and email if HTTP endpoint error occurs" do
    bishop_plugin = external_api_clients(:bishop_monitoring)
    api_namespace = api_namespaces(:monitoring_targets)
    bishop_request = stub_request(:get, api_namespace.api_resources.first.properties['url'])
      .to_return(status: 500, body: "Gateway unavailable")

    api_actions(:create_api_action_plugin_bishop_monitoring_web_request).update!(
      payload_mapping: { 'content': 'test body'},
      custom_headers: { 'accept': 'application/json'},
      bearer_token: 'TEST',
      request_url: 'http://www.discord.com',
      http_method: 'post'
    )
  
    target_namespace = api_namespaces(:bishop_monitoring_target_incident)
    discord_request = stub_request(:post, "http://www.discord.com").to_return(status: 200, body: 'Success.')

    sign_in(@user)
    
    # ActiveRecords will be created times the defined max-retries of plugin
    assert_difference 'ApiResource.count', +(1 * bishop_plugin.max_retries)  do
      assert_difference 'ApiAction.count', +(target_namespace.create_api_actions.count * bishop_plugin.max_retries) do
        # 1 send-email (times the defined max-retries of plugin) create-api-action is executed
        assert_difference "ActionMailer::Base.deliveries.count", +(1 * bishop_plugin.max_retries) do
          get start_api_namespace_external_api_client_path(api_namespace_id: api_namespace.id, id: bishop_plugin.id)
          Sidekiq::Worker.drain_all
        end
      end
    end

    assert_requested discord_request
  end

end