require "test_helper"

class CreateOrderAndStripeChekoutSessionTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)

    @create_order_and_stripe_chekout_session_plugin = external_api_clients(:create_order_and_stripe_chekout_session)
    @orders_namespace = api_namespaces(:orders)
    @logger_namespace = api_namespaces(:shop_logs)

    @payload = {
      data:  {
        line_items: [
          {
              product_id: "64545662f38d703e1a0c84f8",
              variant_id: 88132,
              quantity: 1,
              images: ["https://images-api.printify.com/mockup/645a317153c0c42ec001f098/45208/1637/knit-beanie.jpg?camera_label=flat"]
          },
          {
              product_id: "645a2c4115db3e0fca07ae80",
              variant_id: 25928,
              quantity: 1,
              images: ["https://images-api.printify.com/mockup/645a359052982833d9042017/18518/92547/unisex-jersey-short-sleeve-tee.jpg?camera_label=front"]
          }
        ],
        shipping_and_processing_charges: {
          shipping_charge: 2296,
          stripe_processing_fee: 314
        },
        shop_id: api_resources(:shop_1).properties['printify_shop_id'],
        country_code: "NP"
      }
    }

    Sidekiq::Testing.fake!
  end

  test "should create a new order in initialized state and return the stripe's checkout url" do
    stripe_checkout_response = {
      id: "cs_test_chekout_object",
      object: "checkout.session",
      after_expiration: nil,
      allow_promotion_codes: nil,
      amount_subtotal: nil,
      amount_total: nil,
      automatic_tax: {
        enabled: false,
        status: nil
      },
      billing_address_collection: nil,
      cancel_url: "https://example.com/cancel",
      client_reference_id: nil,
      consent: nil,
      consent_collection: nil,
      created: 1686231134,
      currency: nil,
      currency_conversion: nil,
      custom_fields: [],
      custom_text: {
        shipping_address: nil,
        submit: nil
      },
      customer: nil,
      customer_creation: nil,
      customer_details: {
        address: nil,
        email: "example@example.com",
        name: nil,
        phone: nil,
        tax_exempt: "none",
        tax_ids: nil
      },
      customer_email: nil,
      expires_at: 1686231134,
      invoice: nil,
      invoice_creation: nil,
      livemode: false,
      locale: nil,
      metadata: {},
      mode: "payment",
      payment_intent: "pi_1EUmy5285d61s2cIUDDd7XEQ",
      payment_link: nil,
      payment_method_collection: nil,
      payment_method_options: {},
      payment_method_types: [
        "card"
      ],
      payment_status: "unpaid",
      phone_number_collection: {
        enabled: false
      },
      recovered_from: nil,
      setup_intent: nil,
      shipping_address_collection: nil,
      shipping_cost: nil,
      shipping_details: nil,
      shipping_options: [],
      status: "open",
      submit_type: nil,
      subscription: nil,
      success_url: "https://example.com/success",
      total_details: nil,
      url: "https://checkout.stripe.com/c/pay/test_checkout_url"
    }

    stub_request(:post, /https:\/\/api.stripe.com\/v1\/checkout\/sessions/).to_return(status: 200, body: stripe_checkout_response.to_json)

    perform_enqueued_jobs do
      assert_no_difference '@logger_namespace.api_resources.count' do
        assert_difference '@orders_namespace.api_resources.count', +1 do
          post api_external_api_client_webhook_url(version: @orders_namespace.version, api_namespace: @orders_namespace.slug, external_api_client: @create_order_and_stripe_chekout_session_plugin.slug), params: @payload, as: :json
          Sidekiq::Worker.drain_all
        end
      end
    end

    assert_response :success
    assert_equal stripe_checkout_response[:url], response.parsed_body['data']['checkout_url']
    # the newly created orders are in initialized state
    assert_equal 'initialized', @orders_namespace.api_resources.reload.order(created_at: :asc).last.properties['printify_status']
  end

  test "should not create a new order and create a log record of the error when an exception is raised" do
    stripe_checkout_response = {
      error: {
          message: "Stripe test error.",
          type: "invalid_request_error"
      }
    }

    stub_request(:post, /https:\/\/api.stripe.com\/v1\/checkout\/sessions/).to_return(status: 401, body: stripe_checkout_response.to_json)

    perform_enqueued_jobs do
      assert_difference '@logger_namespace.api_resources.count', +1 do
        assert_no_difference '@orders_namespace.api_resources.count' do
          post api_external_api_client_webhook_url(version: @orders_namespace.version, api_namespace: @orders_namespace.slug, external_api_client: @create_order_and_stripe_chekout_session_plugin.slug), params: @payload, as: :json
          Sidekiq::Worker.drain_all
        end
      end
    end

    assert_response :bad_request
    assert_equal stripe_checkout_response[:error][:message], response.parsed_body['message']

    error_log = @logger_namespace.api_resources.reload.order(created_at: :asc).last
    assert_equal stripe_checkout_response[:error][:message], error_log.properties['error']
    assert_equal 'create_order_and_stripe_checkout_session', error_log.properties['source']
  end
end
