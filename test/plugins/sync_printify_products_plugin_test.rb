require "test_helper"
require "rake"

class SyncPrintifyProductsPluginTest < ActionDispatch::IntegrationTest
  setup do
    @printify_account = api_resources(:printify_account)
    @shop = api_resources(:shop_1)
    @sync_printify_products_plugin = external_api_clients(:sync_printify_products)
    @products_namespace = api_namespaces(:products)
    @product = api_resources(:product_2)
    @user = users(:public)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    stub_request(:post, %r{https://api.printify.com/v1/shops/9024703/products/[\w\d]+/publishing_succeeded.json}).to_return(
      status: 200,
      body: ""
      )
  end

  test "#sync_printify_products: should add products if products with matching ids don't exist in violet" do
    stub_request(:get, "https://api.printify.com/v1/shops/9024703/products.json").to_return(
      status: 200,
      body: {
        "current_page": 1,
        "data": [
            {
                "id": "64745ca255cd8341a60a90",
                "title": "Unisex Premium Pullover",
                "description": "Beat the cold with this premium pullover hoodie that’s just the right layer of warm and cozy. Made with three-panel fleece lining, this pullover is double stitched for durability and roomy. Pick one in your favorite color to match your style. <br/><p>.: 80% combed ringspun cotton, 20% polyester<br/>.: Medium-heavy fabric (8.2 oz /yd² (280 g/m²))<br/>.: Regular Fit<br/>.: Runs true to size<br/>.: Tear away label</p>",
                "tags": [
                    "Men's Clothing",
                    "Long Sleeves",
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
    @shop.products.destroy_all
    sign_in(@user)
    perform_enqueued_jobs do
      assert_difference '@shop.products.count', +1 do
        get start_api_namespace_external_api_client_path(api_namespace_id: @products_namespace.id, id: @sync_printify_products_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end

    assert_equal "https://images-api.printify.com/mockup/64745ca255cd8341a60a9549/68053/7923/unisex-premium-pullover-hoodie.jpg?camera_label=front", @shop.products.first.properties['default_image_url']
    assert_equal "64745ca255cd8341a60a90", @shop.products.first.properties['printify_product_id']
    assert_equal 9024703, @shop.products.first.properties['printify_shop_id']

    # should determine correct categoreis and sub categoreis from tags
    assert_equal ["Men's Clothing"], @shop.products.first.properties['categories']
    assert_equal ["Long Sleeves"], @shop.products.first.properties['sub_categories']
  end

  test "#sync_printify_products: should remove products if violet products exists but not in printify response" do
    stub_request(:get, "https://api.printify.com/v1/shops/9024703/products.json").to_return(
      status: 200,
      body: { "data": [] }.to_json
    )

    sign_in(@user)
    perform_enqueued_jobs do
      assert_difference '@shop.products.count', -2 do
        get start_api_namespace_external_api_client_path(api_namespace_id: @products_namespace.id, id: @sync_printify_products_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end
  end

  test "#sync_printify_products: should update products if violet products already exist" do
    stub_request(:get, "https://api.printify.com/v1/shops/9024703/products.json").to_return(
      status: 200,
      body: {
        "current_page": 1,
        "data": [
            {
                "id": "645a2c4115db3e0fca07ae80",
                "title": "Unisex Premium Pullover",
                "description": "Beat the cold with this premium pullover hoodie that’s just the right layer of warm and cozy. Made with three-panel fleece lining, this pullover is double stitched for durability and roomy. Pick one in your favorite color to match your style. <br/><p>.: 80% combed ringspun cotton, 20% polyester<br/>.: Medium-heavy fabric (8.2 oz /yd² (280 g/m²))<br/>.: Regular Fit<br/>.: Runs true to size<br/>.: Tear away label</p>",
                "tags": [
                    "Men's Clothing",
                    "Long Sleeves",
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

    sign_in(@user)
    perform_enqueued_jobs do
      assert_changes '@product.reload.properties' do
        get start_api_namespace_external_api_client_path(api_namespace_id: @products_namespace.id, id: @sync_printify_products_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end
  end
end