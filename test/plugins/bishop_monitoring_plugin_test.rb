require "test_helper"

class BishopMonitoringPluginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_api: true)
  end

  test "#BishopTlsMonitoring: sends HTTP request and email when HTTPS endpoint has near expiry TLS certificate" do
    skip("need to figure out how to stub the Net::HTTP")
    bishop_plugin = external_api_clients(:bishop_tls_monitoring)
    api_resource = api_namespaces(:monitoring_targets)
  end
end