require "test_helper"

class PublishSucceedPluginTest < ActionDispatch::IntegrationTest
  setup do
    @printify_account = api_resources(:printify_account)
    @shop = api_resources(:shop_1)
    @publish_succeed_plugin = external_api_clients(:publish_succeed)
    @products_namespace = api_namespaces(:products)
    @product = api_resources(:product_2)
    stub_request(:get, "https://api.printify.com/v1/shops/9024703/products/645a2c4115db3e0fca07ae80.json").to_return(
      status: 200,
      body: {
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
          "shop_id": 9024703
    }.to_json)

    stub_request(:post, %r{https://api.printify.com/v1/shops/9024703/products/[\w\d]+/publishing_succeeded.json}).to_return(
      status: 200,
      body: ""
      )
  end

  test '#publish_succeed: should add product' do
    @product.destroy
    payload = {
      "id": "653b6be8-2ff7-4ab5-a7a6-6889a8b3bbf5",
      "type": "product:publish:started",
      "created_at": "2022-05-17 15:00:00+00:00",
      "resource": {
        "id": "645a2c4115db3e0fca07ae80",
        "type": "product",
        "data": {
          "shop_id": 9024703,
          "publish_details": {
            "title": true,
            "variants": false,
            "description": true,
            "tags": true,
            "images": false,
            "key_features": false,
            "shipping_template": true
          },
          "action": "create",
          "out_of_stock_publishing": 0
        }
      }
    }
    perform_enqueued_jobs do
      assert_difference '@shop.products.count', +1 do
        post api_external_api_client_webhook_url(version: @products_namespace.version, api_namespace: @products_namespace.slug, external_api_client: @publish_succeed_plugin.slug), params: payload, as: :json
      end
    end
  end

  test '#publish_succeed: should destroy product' do
    payload = {
      "id": "653b6be8-2ff7-4ab5-a7a6-6889a8b3bbf5",
      "type": "product:publish:started",
      "created_at": "2022-05-17 15:00:00+00:00",
      "resource": {
        "id": "645a2c4115db3e0fca07ae80",
        "type": "product",
        "data": {
          "shop_id": 9024703,
          "action": "delete"
        }
      }
    }
    perform_enqueued_jobs do
      assert_difference '@shop.products.count', -1 do
        post api_external_api_client_webhook_url(version: @products_namespace.version, api_namespace: @products_namespace.slug, external_api_client: @publish_succeed_plugin.slug), params: payload, as: :json
      end
    end
  end

  test '#publish_succeed: should update product' do
    payload = {
      "id": "653b6be8-2ff7-4ab5-a7a6-6889a8b3bbf5",
      "type": "product:publish:started",
      "created_at": "2022-05-17 15:00:00+00:00",
      "resource": {
        "id": "645a2c4115db3e0fca07ae80",
        "type": "product",
        "data": {
          "shop_id": 9024703,
          "publish_details": {
            "title": true,
            "variants": false,
            "description": true,
            "tags": true,
            "images": false,
            "key_features": false,
            "shipping_template": true
          },
          "action": "create",
          "out_of_stock_publishing": 0
        }
      }
    }
    perform_enqueued_jobs do
      assert_no_difference '@shop.products.count' do
        assert_changes '@product.reload.properties' do
          post api_external_api_client_webhook_url(version: @products_namespace.version, api_namespace: @products_namespace.slug, external_api_client: @publish_succeed_plugin.slug), params: payload, as: :json
        end
      end
    end
  end
end
