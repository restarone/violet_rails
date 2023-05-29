require "test_helper"

class Rack::MiniProfilerTest < ActionDispatch::IntegrationTest
  setup do
    stub_request(:get, "https://restcountries.com/v3.1/all").to_return(body: [{ name: { common: 'United States' }, cca2: 'US' }].to_json, status: 200, headers: {'Content-Type': 'application/json'})
    stub_request(:get, "https://api.printify.com/v1/shops.json").to_return(
      status: 200,
      body: [
        {
            "id": 9024703,
            "title": "Restarone",
            "sales_channel": "custom_integration"
        },
        {
            "id": 9448906,
            "title": "Restarone not to sync",
            "sales_channel": "custom_integration"
        }
      ].to_json)

    stub_request(:post, "https://api.printify.com/v1/shops/9024703/webhooks.json").to_return(
      status: 200,
      body: {
        "topic": "order:created",
        "url": "https://example.com/webhooks/order/created",
        "shop_id": 9024703,
        "id": "5cb87a8cd490a2ccb256cec4"
      }.to_json)

    stub_request(:get, "https://api.printify.com/v1/shops/9024703/products.json").to_return(
      status: 200,
      body: {
        "current_page": 1,
        "data": [
            {
                "id": "64745ca255cd8341a60a9549",
                "title": "Unisex Premium Pullover Hoodie",
                "description": "Beat the cold with this premium pullover hoodie that’s just the right layer of warm and cozy. Made with three-panel fleece lining, this pullover is double stitched for durability and roomy. Pick one in your favorite color to match your style. <br/><p>.: 80% combed ringspun cotton, 20% polyester<br/>.: Medium-heavy fabric (8.2 oz /yd² (280 g/m²))<br/>.: Regular Fit<br/>.: Runs true to size<br/>.: Tear away label</p>",
                "tags": [
                    "Men's Clothing",
                    "Hoodies",
                    "Long Sleeves",
                    "Women's Clothing",
                    "DTG",
                    "Unisex"
                ],
                "options": [
                    {
                        "name": "Colors",
                        "type": "color",
                        "values": [
                            {
                                "id": 2420,
                                "title": "White",
                                "colors": [
                                    "#ffffff"
                                ]
                            }
                        ]
                    },
                    {
                        "name": "Sizes",
                        "type": "size",
                        "values": [
                            {
                                "id": 13,
                                "title": "XS"
                            }
                        ]
                    }
                ],
                "variants": [
                    {
                        "id": 68164,
                        "sku": "27538778516873108953",
                        "cost": 2670,
                        "price": 4450,
                        "title": "White / XS",
                        "grams": 437,
                        "is_enabled": true,
                        "is_default": true,
                        "is_available": true,
                        "options": [
                            2420,
                            13
                        ],
                        "quantity": 1
                    }
                ],
                "images": [
                    {
                        "src": "https://images-api.printify.com/mockup/64745ca255cd8341a60a9549/68053/7923/unisex-premium-pullover-hoodie.jpg?camera_label=front",
                        "variant_ids": [
                            68053,
                            68051,
                            68052,
                            68054,
                            68055,
                            68164
                        ],
                        "position": "front",
                        "is_default": true,
                        "is_selected_for_publishing": true
                    }
                ],
                "created_at": "2023-05-29 08:04:50+00:00",
                "updated_at": "2023-05-29 08:05:13+00:00",
                "visible": true,
                "is_locked": false,
                "external": {
                    "id": "1068",
                    "handle": "https://violet-test.net/shop"
                },
                "blueprint_id": 439,
                "user_id": 13202573,
                "shop_id": 9024703,
            },
        ],
        "first_page_url": "/?page=1",
        "from": 1,
        "last_page": 1,
        "last_page_url": "/?page=1",
        "links": [
            {
                "url": nil,
                "label": "&laquo; Previous",
                "active": false
            }
        ],
        "next_page_url": nil,
        "path": "/",
        "per_page": 100,
        "prev_page_url": nil,
        "to": 21,
        "total": 21
    }.to_json)

    stub_request(:post, %r{https://api.printify.com/v1/shops/9024703/products/[\w\d]+/publishing_succeeded.json}).to_return(
      status: 200,
      body: ""
      )
  end

  test 'should install all the namespaces' do
    ENV['SHOP_NAME'] = 'Restarone'
    ENV['PRINTIFY_API_KEY'] = '1234asc'
    ENV['STRIPE_SECRET_KEY'] = 'qw123'

    load Rails.root.join("installer/printify_plugin.rb")
    Sidekiq::Worker.drain_all

    # printify_accounts namespace and resource should be created
    assert ApiNamespace.friendly.find('printify_accounts').present?

    # shops namespace should be created and Restarone should be synced from printify
    shop_namespace = ApiNamespace.friendly.find('shops')
    assert shop_namespace.present?
    assert shop_namespace.api_resources.jsonb_search(:properties, { title: "Restarone" }).present?
    refute shop_namespace.api_resources.jsonb_search(:properties, { title: "Restarone not to sync" }).present?
    
    #products namespace should be created
    products_namespace = ApiNamespace.friendly.find('products')
    assert products_namespace.persisted?

    # sync_printify_products plugin should exist
    assert ExternalApiClient.friendly.find('sync_printify_shops').persisted?

    # publish_succeed plugin should exist
    assert ExternalApiClient.friendly.find('publish_succeed').persisted?

    # only request from printify / headers with valid X-Pfy-Signature should be able to access the publish_succeed plugin

    # orders namespace should be created
    assert ApiNamespace.friendly.find('orders').persisted?

    # fetch_printify_shipping_and_stripe_processing_fees plugin should exist
    assert ExternalApiClient.friendly.find('fetch_printify_shipping_and_stripe_processing_fees').persisted?

    # create_order_and_stripe_chekout_session plugin should exist
    assert ExternalApiClient.friendly.find('create_order_and_stripe_chekout_session').persisted?

    # fulfill_order plugin should exist
    assert ExternalApiClient.friendly.find('fulfill_order').persisted?

    # cleanup_unprocessed_orders_plugin should exist
    assert ExternalApiClient.friendly.find('clean_unprocessed_orders').persisted?

    # clean_unprocessed_orders_manually should exist
    assert ExternalApiClient.friendly.find('clean_unprocessed_orders_manually').persisted?

    # order_status_notification_plugin plugin should exist
    assert ExternalApiClient.friendly.find('order_status_notification').persisted?

    # only request from printify / headers with valid X-Pfy-Signature should be able to access the order_status_notification_plugin plugin

    # notifications namespace should be created
    assert ApiNamespace.friendly.find('notifications').persisted?

    # notifications namespace should have a email create api action

    # order_cleanup_logs namespace should be created
    assert ApiNamespace.friendly.find('order_cleanup_logs').persisted?

    # should subscribe to printify webhook

    # should sync printify prodcuts
    assert_equal 1, products_namespace.api_resources.count

    # printify-shop layout should be created
    cms_site = Comfy::Cms::Site.first
    assert cms_site.layouts.find_by(identifier: 'printify-shop').persisted?

    #####################   SNIPPETS    ##########################

    # products snippet should exist
    assert cms_site.snippets.find_by(identifier: 'products').persisted?

    # products-show snippet should exist

    # navbar-custom-shop anippet should exist

    # products-multi-item-carousel snippet should exist

    #####################   SCRIPTS    ##########################

    # custom-shop-script snippet should exist

    # product-details-script snippet should exist

    # cart-script snippet should exist

    # checkout-success-script should exist

    #####################   ICONS    ##########################

    # cart-icon snippet should exist

    # trash-icon snippet should exist

    # check-icon snippet should exist

    # carousel-control-next-icon snippet should exist

    # carousel-control-prev-icon snippet should exist

    #####################     PAGES      ########################
    
    # products page should exist

    # product-details page should exist

    # cart page should exist

    # checkout-success page should exist

  end
end