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
    load Rails.root.join("installer/printify_plugin.rb")
    Sidekiq::Worker.drain_all

    # printify_accounts namespace and resource should be created

    # shops namespace should be created and Restarone should be synced from printify
    
    #products namespace should be created

    # sync_printify_products plugin should exist

    # publish_succeed plugin should exist

    # only request from printify / headers with valid X-Pfy-Signature should be able to access the publish_succeed plugin

    # orders namespace should be created

    # fetch_printify_shipping_and_stripe_processing_fees plugin should exist

    # create_order_and_stripe_chekout_session plugin should exist

    # fulfill_order plugin should exist

    # cleanup_unprocessed_orders_plugin should exist

    # clean_unprocessed_orders_manually should exist

    # order_status_notification_plugin plugin should exist

    # only request from printify / headers with valid X-Pfy-Signature should be able to access the order_status_notification_plugin plugin

    # notifications namespace should be created

    # notifications namespace should have a email create api action

    # order_cleanup_logs namespace should be created

    # should subscribe to printify webhook

    # should sync printify prodcuts

    # printify-shop layout should be created

    #####################   SNIPPETS    ##########################

    # products snippet should exist

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