require "test_helper"
require "rake"

class CleanUnprocessedOrdersTest < ActiveSupport::TestCase
  setup do
    @order_namespace = api_namespaces(:order)
    @logger_namespace = api_namespaces(:order_cleanup_logs)
    @clean_unprocessed_orders_plugin = external_api_clients(:clean_unprocessed_orders)

    @unprocessed_order_1 = api_resources(:unprocessed_order)
    @unprocessed_order_2 = api_resources(:old_unprocessed_order)
    @unprocessed_order_1.update!(created_at: Time.zone.now - 2.hours)
    @unprocessed_order_2.update!(created_at: Time.zone.now - 2.hours)

    Sidekiq::Testing.fake!
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  teardown do
    Rake::Task.clear
  end

  test '#clean_unprocessed_orders: runs and unprocessed orders are deleted if a day has passed by' do
    @clean_unprocessed_orders_plugin.update(last_run_at: Time.zone.now - 2.days)
    initial_run_at = @clean_unprocessed_orders_plugin.last_run_at

    assert @order_namespace.api_resources.find_by(id: @unprocessed_order_1.id)
    assert @order_namespace.api_resources.find_by(id: @unprocessed_order_2.id)

    perform_enqueued_jobs do
      Rake::Task["external_api_client:drive_cron_jobs"].invoke
      Sidekiq::Worker.drain_all

      refute_equal initial_run_at, @clean_unprocessed_orders_plugin.reload.last_run_at
      refute @order_namespace.api_resources.reload.find_by(id: @unprocessed_order_1.id)
      refute @order_namespace.api_resources.reload.find_by(id: @unprocessed_order_2.id)
    end
  end
end