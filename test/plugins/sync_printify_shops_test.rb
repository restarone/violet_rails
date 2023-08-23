require "test_helper"
require "rake"

class SyncPrintifyShopsTest < ActionDispatch::IntegrationTest
  setup do
    @printify_account = api_resources(:printify_account)
    @shop_namespace = api_namespaces(:shops)
    @shop_namespace.update(associations: [{ type: 'belongs_to', namespace: 'printify_accounts' }])
    @sync_printify_shops_plugin = external_api_clients(:sync_printify_shops)
    @user = users(:public)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
  end

  test '#sync_printify_shops: should only sync shops based on shops_to_sync property in printify_account' do
    stub_request(:get, "https://api.printify.com/v1/shops.json").to_return(
      status: 200,
      body: [
        {
            "id": 9024709,
            "title": "Restarone",
            "sales_channel": "custom_integration"
        },
        {
            "id": 9448906,
            "title": "Restarone not to sync",
            "sales_channel": "custom_integration"
        }
      ].to_json)

    sign_in(@user)
    perform_enqueued_jobs do
      assert_difference '@shop_namespace.api_resources.count', +1 do
        get start_api_namespace_external_api_client_path(api_namespace_id: @shop_namespace.id, id: @sync_printify_shops_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end

    assert_includes @shop_namespace.api_resources.pluck(:properties).pluck('title'), 'Restarone'
    refute_includes @shop_namespace.api_resources.pluck(:properties).pluck('title'), 'Restarone not to sync'

    props = @printify_account.properties
    props['shops_to_sync'] = ['Restarone', 'Restarone not to sync']
    @printify_account.update(properties: props)

    perform_enqueued_jobs do
      assert_difference '@shop_namespace.api_resources.count', +1 do
        get start_api_namespace_external_api_client_path(api_namespace_id: @shop_namespace.id, id: @sync_printify_shops_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end

    assert_includes @shop_namespace.api_resources.pluck(:properties).pluck('title'), 'Restarone'
    assert_includes @shop_namespace.api_resources.pluck(:properties).pluck('title'), 'Restarone not to sync'

    props = @printify_account.properties
    props['shops_to_sync'] = ['Restarone']
    @printify_account.update(properties: props)

    # should not delete shops when removed from 'shops_to_sync', it should be manual
    perform_enqueued_jobs do
      assert_no_difference '@shop_namespace.api_resources.count' do
        get start_api_namespace_external_api_client_path(api_namespace_id: @shop_namespace.id, id: @sync_printify_shops_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end

    assert_includes @shop_namespace.api_resources.pluck(:properties).pluck('title'), 'Restarone'
    assert_includes @shop_namespace.api_resources.pluck(:properties).pluck('title'), 'Restarone not to sync'
  end

  test '#sync_printify_shops: should update shop' do
    stub_request(:get, "https://api.printify.com/v1/shops.json").to_return(
      status: 200,
      body: [
        {
            "id": 9024703,
            "title": "Restarone",
            "sales_channel": "test_integration"
        }
      ].to_json)

    sign_in(@user)
    perform_enqueued_jobs do
      assert_changes "@shop_namespace.api_resources.first.reload.properties['sales_channel']" do
        get start_api_namespace_external_api_client_path(api_namespace_id: @shop_namespace.id, id: @sync_printify_shops_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end
  end
end