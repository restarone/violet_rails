require "test_helper"

class CleanUnprocessedOrdersManuallyTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
    @order_namespace = api_namespaces(:order)
    @logger_namespace = api_namespaces(:order_cleanup_logs)
    @unprocessed_orders_cleanup_plugin = external_api_clients(:clean_unprocessed_orders_manually)
  end

  test "#clean_unprocessed_orders_manually: deletes only the unprocessed orders that falls within the provided date-time range" do
    metadata = {
      'START_TIME': Time.zone.now.beginning_of_day.to_s,
      'END_TIME': Time.zone.now,
      'LOGGER_NAMESPACE': @logger_namespace.slug
    }
    @unprocessed_orders_cleanup_plugin.update(metadata: metadata)


    unprocessed_order = api_resources(:unprocessed_order)
    old_unprocessed_order = api_resources(:old_unprocessed_order)
    sign_in(@user)

    assert @order_namespace.api_resources.find_by(id: unprocessed_order.id)
    assert @order_namespace.api_resources.find_by(id: old_unprocessed_order.id)

    perform_enqueued_jobs do
      assert_difference '@logger_namespace.api_resources.count', +1 do
        assert_difference '@order_namespace.api_resources.count', -1 do
          get start_api_namespace_external_api_client_path(api_namespace_id: @order_namespace.id, id: @unprocessed_orders_cleanup_plugin.id)
          Sidekiq::Worker.drain_all
        end
      end
    end

    assert_response :redirect

    # Only the unprocessed order specified within the date-time range is deleted
    refute @order_namespace.api_resources.find_by(id: unprocessed_order.id)
    assert @order_namespace.api_resources.find_by(id: old_unprocessed_order.id)

    # A log is created
    assert @logger_namespace.api_resources.jsonb_search(
      :properties,
      {
        before_cleanup_orders: {
          value: [unprocessed_order.id],
          option: 'PARTIAL'
        },
        cleanup_status: 'completed',
        source: 'clean_unprocessed_orders_manually'
      }
    ).present?

    refute @logger_namespace.api_resources.jsonb_search(
      :properties,
      {
        before_cleanup_orders: {
          value: [old_unprocessed_order.id],
          option: 'PARTIAL'
        },
        cleanup_status: 'completed',
        source: 'clean_unprocessed_orders_manually'
      }
    ).present?
  end
end