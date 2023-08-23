require "test_helper"

class FetchPrintifyShippingAndStripeProcessingFeesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)

    @fetch_printify_shipping_and_processing_fees_plugin = external_api_clients(:fetch_printify_shipping_and_processing_fees)
    @shops_namespace = api_namespaces(:shops)
    @products_namespace = api_namespaces(:products)
    @logger_namespace = api_namespaces(:shop_logs)

    @payload = {
      data: {
        shop_id: api_resources(:shop_1).properties['printify_shop_id'],
        line_items: [
          {
            product_id: '64545662f38d703e1a0c84f8',
            variant_id: 88132,
            quantity: 1
          },
          {
            product_id: '645a2c4115db3e0fca07ae80',
            variant_id: 21628,
            quantity: 1
          }
        ],
        address_to: {
          country: 'CA'
        }
      }
    }
    @shop = ApiNamespace.friendly.find(@fetch_printify_shipping_and_processing_fees_plugin.metadata['SHOP_NAMESPACE_SLUG']).api_resources.jsonb_search(:properties, {printify_shop_id: @payload[:data][:shop_id]}).first

    @predefined_shipping_charge = 3998

    Sidekiq::Testing.fake!
  end

  test "should fetch the provided products price according to products namespace's resources, shipping information from Printify's API and stripe's processing fees (when pass_stripe_processing_fees_to_customer flag is set)" do
    stub_request(:post, /https:\/\/api.printify.com\/v1\/shops\/*/).to_return(status: 200, body: {
      standard: @predefined_shipping_charge
    }.to_json)

    perform_enqueued_jobs do
      assert_no_difference '@logger_namespace.api_resources.count' do
        post api_external_api_client_webhook_url(version: @shops_namespace.version, api_namespace: @shops_namespace.slug, external_api_client: @fetch_printify_shipping_and_processing_fees_plugin.slug), params: @payload, as: :json
        Sidekiq::Worker.drain_all
      end
    end

    assert_response :success

    # Total of provided line items are calculated according to the price saved in products-namespace's resources
    cart_line_items_total = 0
    @payload[:data][:line_items].each do |line_item|
      product = @products_namespace.api_resources.jsonb_search(:properties, { printify_product_id: line_item[:product_id] }).first
      variant = product.properties['variants'].find { |v| v['id'].to_s == line_item[:variant_id].to_s }

      price = variant['price'].to_i * line_item[:quantity].to_i
      cart_line_items_total += price
    end

    assert_equal cart_line_items_total, response.parsed_body['data']['cart_total_items_cost']
    # The shipping charge is decided as per the response from printify's api
    assert_equal @predefined_shipping_charge, response.parsed_body['data']['shipping_charge']

    expected_processing_fees = stripe_processing_fees(
      cart_line_items_total,
      @predefined_shipping_charge,
      @shop.properties['pass_processing_fees_to_customer'],
      @fetch_printify_shipping_and_processing_fees_plugin.metadata["STRIPE_CAP_AMOUNT"].to_f,
      @fetch_printify_shipping_and_processing_fees_plugin.metadata["STRIPE_PROCESSING_FEE_PERCENTAGE"],
      @shop.properties['collect_sales_tax'],
      @fetch_printify_shipping_and_processing_fees_plugin.metadata["STRIPE_TAX_FEE_PERCENTAGE"],
      @shop.properties['stripe_processing_fee_margin_percentage'].to_f
    )
    assert_equal expected_processing_fees[:stripe_processing_fee], response.parsed_body['data']['stripe_processing_fee']
    assert_equal expected_processing_fees[:total_amount_to_charge_customer], response.parsed_body['data']['total_amount_to_charge_customer']
    assert_equal @shop.properties['currency'], response.parsed_body['data']['currency']
  end

  test "should not include processing fees if pass_processing_fees_to_customer flag is unset" do
    stub_request(:post, /https:\/\/api.printify.com\/v1\/shops\/*/).to_return(status: 200, body: {
      standard: @predefined_shipping_charge
    }.to_json)

    @shop.properties['pass_processing_fees_to_customer'] = false
    @shop.save!

    perform_enqueued_jobs do
      assert_no_difference '@logger_namespace.api_resources.count' do
        post api_external_api_client_webhook_url(version: @shops_namespace.version, api_namespace: @shops_namespace.slug, external_api_client: @fetch_printify_shipping_and_processing_fees_plugin.slug), params: @payload, as: :json
        Sidekiq::Worker.drain_all
      end
    end

    assert_response :success

    # Total of provided line items are calculated according to the price saved in products-namespace's resources
    cart_line_items_total = 0
    @payload[:data][:line_items].each do |line_item|
      product = @products_namespace.api_resources.jsonb_search(:properties, { printify_product_id: line_item[:product_id] }).first
      variant = product.properties['variants'].find { |v| v['id'].to_s == line_item[:variant_id].to_s }

      price = variant['price'].to_i * line_item[:quantity].to_i
      cart_line_items_total += price
    end

    assert_equal cart_line_items_total, response.parsed_body['data']['cart_total_items_cost']
    # The shipping charge is decided as per the response from printify's api
    assert_equal @predefined_shipping_charge, response.parsed_body['data']['shipping_charge']


    # No stripe processing fees are included
    refute response.parsed_body['data']['stripe_processing_fee']
    # The total is equal to the prices of provided items and its shipping charge
    assert_equal cart_line_items_total + @predefined_shipping_charge, response.parsed_body['data']['total_amount_to_charge_customer']
    assert_equal @shop.properties['currency'], response.parsed_body['data']['currency']
  end

  test "should return bad request if there is issue while fetching shipping charge from Printify" do
    stub_request(:post, /https:\/\/api.printify.com\/v1\/shops\/*/).to_return(status: 400, body: 'Cannot provide shipping informtation')

    perform_enqueued_jobs do
      assert_difference '@logger_namespace.api_resources.count', +1 do
        post api_external_api_client_webhook_url(version: @shops_namespace.version, api_namespace: @shops_namespace.slug, external_api_client: @fetch_printify_shipping_and_processing_fees_plugin.slug), params: @payload, as: :json
        Sidekiq::Worker.drain_all
      end
    end

    assert_response :bad_request
    assert_equal 'Error while fetching shipping charge information!', response.parsed_body['message']

    log_properties = @logger_namespace.api_resources.reload.last.properties
    assert_equal 'fetch_printify_shipping_and_stripe_processing_fees', log_properties['source']
    assert_equal 'Cannot provide shipping informtation', log_properties['response_body']
  end

  private
  def stripe_processing_fees(cart_total, shipping_charge, pass_processing_fees_to_customer, cap_amount, stripe_processing_fee_percentage, collect_sales_tax, stripe_tax_fee_percentage, stripe_processing_fee_margin_percentage)
    hash = {}
    total_amount = cart_total + shipping_charge

    if pass_processing_fees_to_customer
      processing_fee_percentage = stripe_processing_fee_percentage.to_f / 100
      processing_fee_percentage += stripe_tax_fee_percentage.to_f / 100 if collect_sales_tax

      total_amount_to_charge_customer = ((total_amount + cap_amount) / (1 - processing_fee_percentage)).ceil
      stripe_processing_fee = total_amount_to_charge_customer - total_amount

      # Margin on Stripe processing fee
      unless stripe_processing_fee_margin_percentage.zero?
        stripe_processing_fee += (stripe_processing_fee * stripe_processing_fee_margin_percentage / 100).ceil
        total_amount_to_charge_customer = total_amount + stripe_processing_fee
      end

      hash[:stripe_processing_fee] = stripe_processing_fee
      hash[:total_amount_to_charge_customer] = total_amount_to_charge_customer
    end

    hash
  end
end
