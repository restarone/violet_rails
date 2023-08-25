require "test_helper"

class ShopsDetailTest < ActionDispatch::IntegrationTest
  setup do
    @shops_namespace = api_namespaces(:shops)
    @logger_namespace = api_namespaces(:shop_logs)
    @shops_detail_plugin = external_api_clients(:shops_detail)
  end

  test '#shops_detail: should return successful response with needed details of existing shops' do
    assert_no_difference "@logger_namespace.api_resources.count" do
      post api_external_api_client_webhook_url(version: @shops_namespace.version, api_namespace: @shops_namespace.slug, external_api_client: @shops_detail_plugin.slug), as: :json
    end
    
    assert_response :success

    parsed_response = response.parsed_body
    assert_equal @shops_namespace.api_resources.count, parsed_response['data']['shops_detail'].size
    parsed_response['data']['shops_detail'].each do |shop_detail|
      shop = @shops_namespace.api_resources.jsonb_search(:properties, { printify_shop_id: shop_detail['shop_id'] }).first

      assert shop
      assert_equal shop.properties['printify_shop_id'], shop_detail['shop_id']
      assert_equal shop.properties['currency'], shop_detail['currency']
      assert_equal shop.properties['collect_sales_tax'], shop_detail['collect_sales_tax']
      assert_equal shop.properties['pass_processing_fees_to_customer'], shop_detail['pass_processing_fees_to_customer']
      assert_equal shop.properties['shipping_countries'].size, shop_detail['shipping_countries'].size
      assert_equal shop.properties['shipping_countries'].to_json, shop_detail['shipping_countries'].to_json
    end
  end
end
