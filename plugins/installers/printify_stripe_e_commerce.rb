SHOPS_TO_SYNC = [ENV['SHOP_NAME']]

p "*** [FAILED]: PLEASE PROVIDE SHOP_NAME TO CONTINUE  ***" and return if ENV['SHOP_NAME'].nil?

PRINTIFY_API_KEY = ENV['PRINTIFY_API_KEY']

p "*** [FAILED]: PLEASE PROVIDE PRINTIFY_API_KEY TO CONTINUE  ***" and return if PRINTIFY_API_KEY.nil?

STRIPE_SECRET_KEY = ENV['STRIPE_SECRET_KEY']

BUSINESS_NAME = ENV['BUSINESS_NAME'] || 'My Printify Account'

PRODUCTS_PAGE_SLUG = ENV['PRODUCTS_PAGE_SLUG'] || 'products'

WEBHOOK_SECRET = SecureRandom.hex

PRODUCT_CATEGORIES = ["Men's Clothing", "Women's Clothing", "Home & Living", "Accessories", "Kids' Clothing"]

PRODUCT_SUB_CATEGORIES = ["T-shirts", "Hoodies", "Sweatshirts", "Long Sleeves", "Tank Tops", "Sportswear", "Bottoms", "Swimwear", "Shoes", "Skirts & Dresses", "Baby Clothing", "Face Masks", "Phone Cases", "Bags", "Socks", "Underwear", "Hats", "Baby Accessories", "Mouse Pads", "Pets", "Kitchen Accessories", "Car Accessories", "Tech Accessories", "Travel Accessories", "Stationery Accessories", "Mugs", "Glassware", "Bottles & Tumblers", "Canvas", "Posters", "Postcards", "Ornaments", "Journals & Notebooks", "Magnets & Stickers", "Home Decor", "Bathroom", "Towels", "Blankets", "Pillows & Covers", "Games", "Rugs & Mats", "Seasonal Decorations", "Other"]

PRINTIFY_HEADERS = {
  "Content-Type" => 'application/json;charset=utf-8',
  "Authorization" => "Bearer #{PRINTIFY_API_KEY}" 
}

printify_response = HTTParty.get("https://api.printify.com/v1/shops.json", headers: PRINTIFY_HEADERS)

p "[FAILED] with error: #{printify_response.body}" and return unless printify_response.success?

shop_exists = JSON.parse(printify_response.body).any? { |s| ENV['SHOP_NAME'] == s['title']}

p "[FAILED]: Shop with name #{ENV['SHOP_NAME']} doesn't exist in printify. Please make sure SHOP_NAME matches the name of your printify store." and return unless shop_exists

site = Comfy::Cms::Site.first

p "###################################                    CREATING CATEGORIES                    ###################################"

namespace_category = Comfy::Cms::Category.where(label: "printify-shop", categorized_type: "ApiNamespace").first_or_create

layout_category = Comfy::Cms::Category.where(label: "printify-shop", categorized_type: "Comfy::Cms::Layout", site: site).first_or_create
page_category = Comfy::Cms::Category.where(label: "printify-shop", categorized_type: "Comfy::Cms::Page", site: site).first_or_create
snippet_category = Comfy::Cms::Category.where(label: "printify-shop", categorized_type: "Comfy::Cms::Snippet", site: site).first_or_create
icon_snippet_category = Comfy::Cms::Category.where(label: "icon", categorized_type: "Comfy::Cms::Snippet", site: site).first_or_create
script_category = Comfy::Cms::Category.where(label: "script", categorized_type: "Comfy::Cms::Snippet", site: site).first_or_create

p "###################################   CREATING PRINTIFY ACCOUNTS, SHOP, SHOP_LOGS NAMEPACES   ###################################"

printify_account_namespace = ApiNamespace.create(name: 'printify_accounts', version: 1, requires_authentication: true, properties: { stripe_secret_key: '', api_key: '', name: '', shops_to_sync: [] }, category_ids: [namespace_category.id])

printify_account = printify_account_namespace.api_resources.create(properties: { stripe_secret_key: STRIPE_SECRET_KEY, api_key: PRINTIFY_API_KEY, name: BUSINESS_NAME, shops_to_sync: SHOPS_TO_SYNC })

countries_response = HTTParty.get("https://restcountries.com/v3.1/all")
countries = countries_response.success? ? (countries_response.parsed_response.map {|resp| {country_name: resp['name']['common'], country_code: resp['cca2']}}.sort_by {|obj| obj[:country_name]}) : [{"country_code"=>"US", "country_name"=>"United States"}, {"country_code"=>"CA", "country_name"=>"Canada"}]

shop_namespace = ApiNamespace.create(
  name: 'shops',
  version: 1,
  requires_authentication: true,
  properties: {
    printify_shop_id: '',
    title: '',
    sales_channel: '',
    printify_account_id: '',
    collect_sales_tax: true,
    pass_processing_fees_to_customer: true,
    stripe_processing_fee_margin_percentage: 0,
    shipping_countries: countries,
    currency: 'USD',
    product_categories: PRODUCT_CATEGORIES,
    product_sub_categories: PRODUCT_SUB_CATEGORIES 
  },
  associations: [{ type: 'belongs_to', namespace: 'printify_accounts' }],
  category_ids: [namespace_category.id]
)

ApiNamespace.create(name: 'shop_logs', version: 1, requires_authentication: true, properties: { type: '', source: '', response: {}, extra: {}, timestamp: '' }, category_ids: [namespace_category.id], associations: [{ type: 'belongs_to', namespace: 'shops' }])

sync_printify_shops_plugin = ExternalApiClient.create(
  api_namespace_id: shop_namespace.id,
  label: "sync_printify_shops",
  enabled: true,
  drive_strategy: "on_demand",
  metadata: { LOGGER_NAMESPACE: "shop_logs" },
  model_definition: <<~RUBY
                    class SyncPrintifyShops
                      def initialize(parameters)
                        @external_api_client = parameters[:external_api_client]
                      end
                      
                      def start
                        ApiNamespace.friendly.find('printify_accounts').api_resources.each do |printify_account|
                          response = HTTParty.get("https://api.printify.com/v1/shops.json",
                            headers: {
                              "Content-Type" => "application/json;charset=utf-8",
                              "Authorization" => "Bearer \#{printify_account.properties['api_key']}"
                            })
                          
                          if response.success?
                            JSON.parse(response.body).filter { |s| printify_account.properties["shops_to_sync"].include?(s['title']) }.each do |shop_object|
                              shop = printify_account.shops.jsonb_search(:properties, { printify_shop_id: shop_object['id'] }).first_or_initialize
                              properties = shop.properties
                              properties['printify_shop_id'] = shop_object['id']
                              properties['title'] = shop_object['title']
                              properties['sales_channel'] = shop_object['sales_channel']
                              properties['printify_account_id'] = printify_account.id
                              shop.properties = properties
                              shop.save!
                            end
                          else
                            ApiNamespace.friendly.find(@external_api_client.metadata['LOGGER_NAMESPACE']).api_resources.create(properties: {
                                status: 'error',
                                response: response.body,
                                source: 'sync_printify_shops',
                                printify_account_id: printify_account.id,
                                timestamp: Time.zone.now
                              })
                          end
                        end
                      end
                    end
                    
                    SyncPrintifyShops
                    RUBY
)

shops_details_plugin = ExternalApiClient.create(
  api_namespace_id: shop_namespace.id,
  label: "shops_detail",
  enabled: true,
  drive_strategy: "webhook",
  metadata: { LOGGER_NAMESPACE: "shop_logs" },
  model_definition: <<~RUBY
                    class ShopsDetail
                      def initialize(parameters)
                        @external_api_client = parameters[:external_api_client]
                        @payload = parameters[:request]&.request_parameters
                        @logger_namespace = ApiNamespace.find_by(slug: @external_api_client.metadata["LOGGER_NAMESPACE"])
                      end
                      
                      def start
                        begin
                          shops = @external_api_client.api_namespace.api_resources
                          shops_detail = []
                    
                          shops.each do |shop|
                            shops_detail << {
                              shop_id: shop.properties['printify_shop_id'],
                              currency: shop.properties['currency'],
                              collect_sales_tax: shop.properties['collect_sales_tax'],
                              pass_processing_fees_to_customer: shop.properties['pass_processing_fees_to_customer'],
                              shipping_countries: shop.properties['shipping_countries']
                            }
                          end
                    
                          render json: {
                            success: true,
                            data: {
                              shops_detail: shops_detail
                            }
                          }
                    
                        rescue => e
                          log_error('shipping_countries_list', e.message, @payload)
                    
                          render json: {
                            success: false,
                            message: e.message
                          }, status: :bad_request
                        end
                      end
                    
                      def log_error(source, message, params)
                        @logger_namespace.api_resources.create!(
                          properties: {
                            source: source,
                            error: message,
                            request_params: params,
                          }
                        )
                      end
                    end
                    
                    ShopsDetail
                    RUBY
)

p "###################################                  RUNNING SHOP SYNC PLUGIN                 ###################################"

ExternalApiClientJob.new.perform(sync_printify_shops_plugin.id, {})

p "###################################           CREATING PRODUCTS NAMESPACE AND PLUGINS         ###################################"

products_namespace = ApiNamespace.create(
  name: 'products', 
  version: 1,
  requires_authentication: false,
  properties: {
    tags: [],
    title: '',
    images: [],
    options: [],
    shop_id: '',
    visible: true,
    variants: [],
    description: '',
    printify_shop_id: '',
    default_image_url: '',
    printify_product_id: '',
    categories: [],
    sub_categories: []
  },
  associations: [{type: 'belongs_to', namespace: 'shops'}],
  category_ids: [namespace_category.id]
)

sync_printify_products_plugin = products_namespace.external_api_clients.create(
  label: "sync_printify_products",
  enabled: true,
  drive_strategy: "on_demand",
  metadata: { LOGGER_NAMESPACE: "shop_logs" },
  model_definition: <<~RUBY
                    class SyncPrintifyProducts
                      def initialize(parameters)
                        @external_api_client = parameters[:external_api_client]
                        @logger_namespace = ApiNamespace.find_by(slug: @external_api_client.metadata["LOGGER_NAMESPACE"]) if @external_api_client.metadata["LOGGER_NAMESPACE"]
                      end
                    
                      def start
                        ApiNamespace.friendly.find('shops').api_resources.each do |shop|
                          printify_request_headers = {
                                              "Content-Type" => 'application/json;charset=utf-8',
                                              "Authorization" => "Bearer \#{shop.printify_account.properties['api_key']}" 
                                            }
                          product_response = HTTParty.get("https://api.printify.com/v1/shops/\#{shop.properties['printify_shop_id']}/products.json", headers: printify_request_headers)
                      
                          log_error(product_response.body, { shop_id: shop.id }) && return unless product_response.success?
                      
                          printify_product_list = JSON.parse(product_response.body)['data']
                          violet_products = shop.products
                      
                          to_delete = violet_products.pluck(:properties).pluck('printify_product_id') - printify_product_list.pluck('id')
                      
                          violet_products.jsonb_search(:properties, { printify_product_id: { value: to_delete, option: 'PARTIAL', match: 'ANY' }}).map(&:destroy) if to_delete.present?
                      
                          printify_product_list.each do |product_object|
                            product = violet_products.jsonb_search(:properties, { printify_product_id: product_object['id'] }).first_or_initialize
                            enabled_variants = product_object['variants'].filter { |variant| variant['is_enabled'] }
                            enabled_options_map = enabled_variants.map {|variant| variant['options']}
                            enabled_options_ids = enabled_options_map.flatten.uniq 
                            enabled_options = product_object['options'].map do |option|
                              option['values'] = option['values'].filter { |value| enabled_options_ids.include?(value['id']) }
                              option
                            end

                            enabled_options.each do |option|
                              option['values'].each do |value| 
                                value['available_options'] = enabled_options_map.select { |opt| opt.include?(value['id']) }.flatten.uniq.excluding(value['id'])
                              end
                            end

                            default_variant = enabled_variants.find { |variant| variant['is_default'] } || enabled_variants.first
                            default_image = product_object['images'].find { |image| image['is_default'] && image['variant_ids'].include?(default_variant['id']) }        

                            categories = shop.properties['product_categories'] & product_object['tags']
                            sub_categories = shop.properties['product_sub_categories'] & product_object['tags']
                            product.properties = {
                              printify_product_id: product_object['id'],
                              title: product_object['title'],
                              description: product_object['description'],
                              tags: product_object['tags'],
                              variants: enabled_variants,
                              images: product_object['images'],
                              options: enabled_options,
                              visible: product_object['visible'],
                              default_image_url: default_image&.dig('src'),
                              printify_shop_id: product_object['shop_id'],
                              shop_id: shop.id,
                              categories: categories,
                              sub_categories: sub_categories
                            }
                            product.save!
                      
                            publish_response = HTTParty.post("https://api.printify.com/v1/shops/\#{shop.properties['printify_shop_id']}/products/\#{product_object['id']}/publishing_succeeded.json",
                              body: { external: { id: product.id.to_s, handle: "https://\#{ENV['APP_HOST']}/product-details?id=\#{product.id}" }}.to_json,
                              headers: printify_request_headers
                            )
                          
                            log_error(publish_response.body, { shop_id: shop.id, product: product_object['id'] }) unless publish_response.success?
                          end
                        end
                      end
                                      
                      def log_error(response, extra)
                        @logger_namespace.api_resources.create(properties: {
                          status: 'error',
                          timestamp: Time.zone.now,
                          response: response,
                          extra: extra,
                          source: 'sync_products'
                        })
                      end
                    end
                    
                    SyncPrintifyProducts
                    RUBY
)

printify_product_publish_plugin = products_namespace.external_api_clients.create(
  label: "publish_succeed",
  enabled: true,
  drive_strategy: "webhook",
  metadata: { LOGGER_NAMESPACE: "shop_logs" },
  model_definition: <<~RUBY
                    class ProductPublishStartWebhook
                      def initialize(parameters)
                        @external_api_client = parameters[:external_api_client]
                        @payload = parameters[:request]&.request_parameters
                        @logger_namespace = ApiNamespace.find_by(slug: @external_api_client.metadata["LOGGER_NAMESPACE"]) if @external_api_client.metadata["LOGGER_NAMESPACE"]
                        @printify_base_uri = "https://api.printify.com/v1/shops/\#{@payload['resource']['data']['shop_id']}/products/\#{@payload['resource']['id']}"
                        @shop = ApiNamespace.find_by(slug: 'shops').api_resources.jsonb_search(:properties, { printify_shop_id: @payload['resource']['data']['shop_id'] }).first
                        @printify_request_headers = {
                                              'Content-Type': 'application/json;charset=utf-8',
                                              'Authorization': "Bearer \#{@shop.printify_account.properties['api_key']}" }
                      end
                      
                      def start
                        begin
                          product = @external_api_client.api_namespace.api_resources.jsonb_search(:properties, { printify_product_id: @payload['resource']['id'] }).first_or_initialize
                    
                          if @payload['resource']['data']['action'] == 'delete' && product.persisted?
                            product.destroy!
                          else
                            product_response = HTTParty.get("\#{@printify_base_uri}.json", headers: @printify_request_headers)
                            
                            product_object = JSON.parse(product_response.body) 

                            enabled_variants = product_object['variants'].filter { |variant| variant['is_enabled'] }
                            enabled_options_map = enabled_variants.map {|variant| variant['options']}
                            enabled_options_ids = enabled_options_map.flatten.uniq 
                            enabled_options = product_object['options'].map do |option|
                              option['values'] = option['values'].filter { |value| enabled_options_ids.include?(value['id']) }
                              option
                            end

                            enabled_options.each do |option|
                              option['values'].each do |value| 
                                value['available_options'] = enabled_options_map.select { |opt| opt.include?(value['id']) }.flatten.uniq.excluding(value['id'])
                              end
                            end

                            default_variant = enabled_variants.find { |variant| variant['is_default'] } || enabled_variants.first
                            default_image = product_object['images'].find { |image| image['is_default'] && image['variant_ids'].include?(default_variant['id']) }

                            categories = @shop.properties['product_categories'] & product_object['tags']
                            sub_categories = @shop.properties['product_sub_categories'] & product_object['tags']                          
                            product.properties = {
                              printify_product_id: product_object['id'],
                              title: product_object['title'],
                              description: product_object['description'],
                              tags: product_object['tags'],
                              variants: enabled_variants,
                              images: product_object['images'],
                              options: enabled_options,
                              visible: product_object['visible'],
                              default_image_url: default_image&.dig('src'),
                              shop_id: @shop.id,
                              printify_shop_id: product_object['shop_id'],
                              categories: categories,
                              sub_categories: sub_categories
                            }
                            product.save!
                    
                            publish_response = HTTParty.post("\#{@printify_base_uri}/publishing_succeeded.json",
                              body: { external: { id: product.id.to_s, handle: "https://\#{ENV['APP_HOST']}/product-details?id=\#{product.id}" } }.to_json,
                              headers: @printify_request_headers
                            )
                    
                            log_error(publish_response.body, { shop: @shop.id, printify_shop: product.properties['shop_id'], product: product.id }) unless publish_response.success?
                          end
                        rescue StandardError => e
                          log_error(e.message, { shop: @shop.id, printify_shop: @payload['resource']['data']['shop_id'], product: @payload['resource']['id'], error_backtrace: e.backtrace })
                    
                          HTTParty.post("\#{@printify_base_uri}/publishing_failed.json", body: { reason: "Publish Failed" }.to_json, headers: @printify_request_headers)
                        end
                    
                        render json: { result: product }
                      end
                    
                      def log_error(response, extra)
                        @logger_namespace.api_resources.create!(properties: {
                          response: response,
                          extra: extra,
                          timestamp: Time.zone.now,
                          source: 'publish_succeed'
                        })
                      end
                    end
                    
                    ProductPublishStartWebhook
                    RUBY
)

WebhookVerificationMethod.create(
  webhook_type: 'custom',
  external_api_client_id: printify_product_publish_plugin.id,
  webhook_secret: WEBHOOK_SECRET,
  custom_method_definition: <<~RUBY
                            hex_digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), verification_method.webhook_secret.encode('utf-8'), request.body.string.encode('utf-8'))
                            signature = request.headers['X-Pfy-Signature'] || ''
                            if ActiveSupport::SecurityUtils.secure_compare(signature, "sha256=\#{hex_digest}")
                              [true, 'Success']
                            else
                              [false, 'Verification failed']
                            end
                            RUBY

)

p "###################################           CREATING ORDERS NAMESPACE AND PLUGINS           ###################################"

orders_namespace = ApiNamespace.create(
  name: "orders",
  version: 1,
  category_ids: [namespace_category.id],
  associations: [{ type: "belongs_to", namespace: "shops" }, { type: 'has_many', namespace: "shop_logs" }],
  requires_authentication: true,
  properties: {
    printify_order_id: "",
    shipments: [],
    total_tax: "",
    address_to: {},
    line_items: [],
    total_price: "",
    fulfilled_at: "",
    total_shipping: "",
    printify_status: "",
    shipping_method: "",
    printify_shop_id: "",
    stripe_processing_fee: "",
    sent_to_production_at: "",
    passed_processing_fee_to_customer: "",
    sales_tax_collected: "",
    stripe: {
      customer: "",
      amount_tax: 0,
      stripe_fee: 0,
      receipt_url: "",
      amount_total: "",
      amount_total: "",
      payment_intent: "",
      payment_status: "",
      amount_shipping: 0,
      amount_subtotal: 0,
      checkout_session: ""
    }
  })

fetch_printify_shipping_and_stripe_processing_fees_plugin = orders_namespace.external_api_clients.create(
  label: "fetch_printify_shipping_and_stripe_processing_fees",
  enabled: true,
  drive_strategy: "webhook",
  metadata: {
    LOGGER_NAMESPACE: "shop_logs",
    STRIPE_CAP_AMOUNT: 30,
    SHOP_NAMESPACE_SLUG: "shops",
    STRIPE_PROCESSING_FEE_PERCENTAGE: 2.9,
    STRIPE_TAX_FEE_PERCENTAGE: 0.5
  },
  model_definition: <<~RUBY
                    class FetchPrintifyShippingAndStripeProcessingFees
                      def initialize(parameters)
                        @external_api_client = parameters[:external_api_client]
                        @payload = parameters[:request]&.request_parameters
                      end
                      
                      def start
                        begin
                          # Fetching required data
                          printify_shop_id = @payload[:data][:shop_id]
                          raise "Printify Shop ID missing!" if printify_shop_id.blank?
                    
                          shop = ApiNamespace.friendly.find(@external_api_client.metadata['SHOP_NAMESPACE_SLUG']).api_resources.jsonb_search(:properties, {printify_shop_id: printify_shop_id}).first
                          printify_token = shop.printify_account.properties['api_key']
                          raise "Printify API token missing!" if printify_token.blank?
                    
                          logger_namespace = ApiNamespace.find_by!(slug: @external_api_client.metadata["LOGGER_NAMESPACE"])
                          violet_products = shop.products
                    
                          printify_base_uri = "https://api.printify.com/v1/shops/\#{printify_shop_id}"
                          printify_request_headers = {
                                                "Content-Type" => 'application/json;charset=utf-8',
                                                "Authorization" => "Bearer \#{printify_token}" 
                                              }
                    
                          # line_items should contain (product_id, variant_id) and quantity
                          cart_line_items = @payload[:data][:line_items]
                          cart_line_items_total = 0
                    
                          cart_line_items.each do |line_item|
                            product = violet_products.jsonb_search(:properties, { printify_product_id: line_item[:product_id] }).first
                            variant = product.properties['variants'].find { |v| v['id'].to_s == line_item[:variant_id].to_s }
                    
                            price = variant['price'].to_i * line_item['quantity'].to_i
                            cart_line_items_total += price
                          end
                    
                          # Fetching Shipping charges for the provided line_items
                          req_body = {
                            line_items: cart_line_items,
                            address_to: @payload[:data][:address_to]
                          }
                    
                          shipping_charges_response = HTTParty.post(
                            "\#{printify_base_uri}/orders/shipping.json",
                            headers: printify_request_headers,
                            body: req_body.to_json
                          )
                          
                          unless shipping_charges_response.success?
                            logger_namespace.api_resources.create!(
                              properties: {
                                source: 'fetch_printify_shipping_and_stripe_processing_fees',
                                request_body: req_body,
                                response_body: shipping_charges_response.body,
                              }
                            )
                    
                            raise 'Error while fetching shipping charge information!'
                          end
                    
                          shipping_charge = JSON.parse(shipping_charges_response.body)['standard'].to_i
                          total_amount = cart_line_items_total + shipping_charge
                    
                          misc_fees_details = {
                            total_amount_to_charge_customer: total_amount
                          }
                    
                          pass_stripe_processing_fees_to_customer = shop.properties['pass_processing_fees_to_customer']
                          if pass_stripe_processing_fees_to_customer
                            # Determining Stripe's processing fee
                            cap_amount = @external_api_client.metadata["STRIPE_CAP_AMOUNT"].to_f
                            processing_fee_percentage = @external_api_client.metadata["STRIPE_PROCESSING_FEE_PERCENTAGE"].to_f / 100
                            # reference: https://stripe.com/docs/tax/faq#:~:text=Pricing%20for%20Stripe%20Tax%20on,100%2C000%20USD%20in%20a%20month.
                            processing_fee_percentage += @external_api_client.metadata["STRIPE_TAX_FEE_PERCENTAGE"].to_f / 100 if shop.properties['collect_sales_tax']
                    
                            total_amount_to_charge_customer = ((total_amount + cap_amount) / (1 - processing_fee_percentage)).ceil
                            stripe_processing_fee = total_amount_to_charge_customer - total_amount
                    
                            # Margin on Stripe processing fee
                            stripe_processing_fee_margin_percentage = shop.properties['stripe_processing_fee_margin_percentage'].to_f
                            unless stripe_processing_fee_margin_percentage.zero?
                              stripe_processing_fee += (stripe_processing_fee * stripe_processing_fee_margin_percentage / 100).ceil
                              total_amount_to_charge_customer = total_amount + stripe_processing_fee
                            end
                    
                            misc_fees_details[:stripe_processing_fee] = stripe_processing_fee
                            misc_fees_details[:total_amount_to_charge_customer] = total_amount_to_charge_customer
                          end
                    
                    
                          render json: {
                            success: true,
                            data: {
                              cart_total_items_cost: cart_line_items_total,
                              shipping_charge: shipping_charge,
                              currency: shop.properties['currency']
                            }.merge(misc_fees_details)
                          }
                    
                        rescue => e
                          render json: {
                            success: false,
                            message: e.message
                          }, status: :bad_request
                        end
                      end
                    end
                    
                    FetchPrintifyShippingAndStripeProcessingFees          
                    RUBY
)

create_order_and_stripe_chekout_session_plugin = orders_namespace.external_api_clients.create(
  label: "create_order_and_stripe_chekout_session",
  enabled: true,
  drive_strategy: "webhook",
  metadata: {
    CANCEL_URL: "https://#{ENV['APP_HOST']}/cart",
    SUCCESS_URL: "https://#{ENV['APP_HOST']}/products",
    LOGGER_NAMESPACE: "shop_logs",
    SHOP_NAMESPACE_SLUG: "shops",
    PROCESSING_FEE_TAX_CODE: "txcd_20030000"
  },
  model_definition: <<~RUBY
                    class CreateOrderAndStripeChekoutSession
                      def initialize(parameters)
                        @external_api_client = parameters[:external_api_client]
                        @payload = parameters[:request]&.request_parameters
                        @shop = ApiNamespace.friendly.find(@external_api_client.metadata["SHOP_NAMESPACE_SLUG"]).api_resources.jsonb_search(:properties, {printify_shop_id: @payload[:data][:shop_id]}).first
                        @violet_products = @shop.products
                        @success_url = @external_api_client.metadata["SUCCESS_URL"]
                        @cancel_url = @external_api_client.metadata["CANCEL_URL"]
                        @logger_namespace = ApiNamespace.find_by(slug: @external_api_client.metadata["LOGGER_NAMESPACE"])
                        Stripe.api_key = @shop.printify_account.properties['stripe_secret_key']
                      end
                      
                      def start
                        begin
                          ApiNamespace.transaction do
                            # should contain (product_id, variant_id), quantity, images[array] within line_items
                            cart_line_items = @payload[:data][:line_items]
                            shipping_and_processing_charges = @payload[:data][:shipping_and_processing_charges]
                            shipping_country = @payload[:data][:country_code]
                    
                            stripe_line_items = []
                    
                            # Create order
                            violet_order = @external_api_client.api_namespace.api_resources.new
                            properties = violet_order.properties
                            properties['line_items'] = cart_line_items
                            properties['shop_id'] = @shop.id
                            properties['printify_shop_id'] = @shop.properties['printify_shop_id']
                            properties['stripe_processing_fee'] = shipping_and_processing_charges[:stripe_processing_fee]
                            properties['passed_processing_fee_to_customer'] = @shop.properties['pass_processing_fees_to_customer']
                            properties['sales_tax_collected'] = @shop.properties['collect_sales_tax']
                            properties['currency'] = @shop.properties['currency']
                            violet_order.save!
                    
                            # Create request parameters for Stripe Checkout Session
                            stripe_tax_behaviour = @shop.properties['collect_sales_tax'] ? 'exclusive' : 'inclusive'
                            cart_line_items.each do |line_item|
                              product = @violet_products.jsonb_search(:properties, { printify_product_id: line_item[:product_id] }).first
                              variant = product.properties['variants'].find { |v| v['id'].to_s == line_item[:variant_id].to_s }
                    
                              stripe_line_items << {
                                price_data: {
                                  currency: @shop.properties['currency'],
                                  product_data: {name: product.properties['title'], images: line_item[:images] },
                                  unit_amount: variant['price'],
                                  tax_behavior: stripe_tax_behaviour,
                                },
                                quantity: line_item[:quantity]
                              }
                            end
                            
                              if @shop.properties['pass_processing_fees_to_customer']
                                stripe_line_items << {
                                    price_data: {
                                      currency: @shop.properties['currency'],
                                      product_data: { name: 'Convenience fee',
                                                      tax_code: @external_api_client.metadata['PROCESSING_FEE_TAX_CODE']
                                                    },
                                      unit_amount: shipping_and_processing_charges[:stripe_processing_fee],
                                      tax_behavior: stripe_tax_behaviour,
                                      
                                    },
                                    quantity: 1
                                  }
                              end
                              shipping_options = [
                                {
                                  shipping_rate_data: {
                                    type: 'fixed_amount',
                                    fixed_amount: {
                                      amount: shipping_and_processing_charges[:shipping_charge],
                                      currency: @shop.properties['currency'],
                                    },
                                    display_name: 'Standard shipping',
                                  },
                                }]
                            stripe_checkout_session = Stripe::Checkout::Session.create(
                              {
                                metadata: {
                                  order_id: violet_order.id,
                                },
                                line_items: stripe_line_items,
                                mode: 'payment',
                                payment_method_types: ['card'],
                                automatic_tax: {
                                  enabled: @shop.properties['collect_sales_tax']
                                },
                                cancel_url: @cancel_url,
                                success_url: @success_url,
                                shipping_address_collection: {allowed_countries: [shipping_country]},
                                shipping_options: shipping_options
                              }
                            )
                    
                            render json: {
                              success: true,
                              data: {
                                checkout_url: stripe_checkout_session.url
                              }
                            }
                          end
                        rescue => e
                          log_error('create_order_and_stripe_checkout_session', e.message, @payload)
                    
                          render json: {
                            success: false,
                            message: e.message
                          }, status: :bad_request
                        end
                      end
                    
                      def log_error(source, message, params)
                        @logger_namespace.api_resources.create!(
                          properties: {
                            source: source,
                            error: message,
                            request_params: params,
                          }
                        )
                      end
                    end
                    
                    CreateOrderAndStripeChekoutSession          
                    RUBY
)

fulfill_order_plugin = orders_namespace.external_api_clients.create(
  label: "fulfill_order",
  enabled: true,
  drive_strategy: "webhook",
  metadata: {
    LOGGER_NAMESPACE: "shop_logs"
  },
  model_definition: <<~RUBY
                    class FulfillOrder
                      def initialize(parameters)
                        @external_api_client = parameters[:external_api_client]
                        @notification_namespace = ApiNamespace.find_by(slug: @external_api_client.metadata["NOTIFICATION_NAMESPACE"])
                        @logger_namespace = ApiNamespace.find_by(slug: @external_api_client.metadata["LOGGER_NAMESPACE"])
                        @payload = parameters[:request]&.request_parameters
                      end
                      
                      def start
                        if @payload['type'] == 'checkout.session.completed'
                          begin
                            order_id = @payload["data"]["object"]["metadata"]["order_id"]
                            order = @external_api_client.api_namespace.api_resources.find_by_id(order_id)
                            if order.present?
                              Stripe.api_key = order.shop.printify_account.properties['stripe_secret_key']
                              checkout = Stripe::Checkout::Session.retrieve({
                                id: @payload['data']['object']['id'],
                                expand: ['line_items', 'payment_intent.latest_charge.balance_transaction']
                              })
                              fulfill_order(order, checkout)
                              render json: { success: true }
                            else
                              @logger_namespace.api_resources.create(properties: {
                                status: 'error',
                                message: 'Order not found',
                                timestamp: Time.zone.now,
                                request_payload: @payload,
                                source: 'fulfill_order'
                              })
                              render json: { success: false, message: 'An order with the provided ID could not be found' }, status: :not_found
                            end
                          rescue => e
                            @logger_namespace.api_resources.create(properties: {
                                                                    status: 'error',
                                                                    response: e.message,
                                                                    timestamp: Time.zone.now,
                                                                    error_backtrace: e.backtrace,
                                                                    order_id: order&.id,
                                                                    source: 'fulfill_order'
                                                                  })
                            render json: { success: false, message: e.message }, status: :unprocessable_entity
                          end
                        end
                      end
                      
                      def fulfill_order(order, checkout)
                        printify_base_url = "https://api.printify.com/v1/shops/\#{order.properties['printify_shop_id']}/orders"
                        printify_request_headers = {
                          'Content-Type': 'application/json;charset=utf-8',
                          'Authorization': "Bearer \#{order.shop.printify_account.properties['api_key']}" 
                        }
                        line_items = order.properties['line_items'].map do |line_item|
                          {
                            product_id: line_item['product_id'],
                            variant_id: line_item['variant_id'],
                            quantity: line_item['quantity']
                          }
                        end
                        
                        customer_details = checkout.customer_details
                    
                        req_body = {
                                      external_id: order.id.to_s,
                                      line_items: line_items,
                                      shipping_method: 1,
                                      send_shipping_notification: true,
                                      address_to: {
                                        first_name: customer_details.name.split(" ")[0..-2].join(" "),
                                        last_name: customer_details.name.split(" ").last,
                                        email: customer_details.email,
                                        phone: customer_details.phone,
                                        country: customer_details.address.country,
                                        region: customer_details.address.state,
                                        address1: customer_details.address.line1,
                                        address2: customer_details.address.line2,
                                        city: customer_details.address.city,
                                        zip: customer_details.address.postal_code
                                      }
                                    }
                        
                        printify_order = HTTParty.post("\#{printify_base_url}.json",
                          body: req_body.to_json,
                          headers: printify_request_headers
                        )
                        
                        if printify_order.success?
                          printify_order_resp = HTTParty.get("\#{printify_base_url}/\#{JSON.parse(printify_order.body)['id']}.json",
                            headers: printify_request_headers
                          )
                          printify_order = JSON.parse(printify_order_resp.body)
                    
                          properties = order.properties
                          properties["printify_order_id"] = printify_order["id"]
                          properties["shipments"] = printify_order["shipments"]
                          properties["address_to"] = printify_order["address_to"]
                          properties["line_items"] = printify_order["line_items"]
                          properties["total_tax"] = printify_order["total_tax"]
                          properties["printify_status"] = printify_order["status"]
                          properties["total_price"] =  printify_order["line_items"].sum { |item|  item['metadata']['price'].to_f * item['quantity'].to_i }
                          properties["fulfilled_at"] = printify_order["fulfilled_at"]
                          properties["total_shipping"] = printify_order["total_shipping"]
                          properties["shipping_method"] = printify_order["shipping_method"]
                          properties["printify_shop_id"] = printify_order["shop_id"]
                          properties["sent_to_production_at"] = printify_order["sent_to_production_at"]
                          properties["shop_id"] = order.shop.id
                          properties["stripe"] = {
                            customer: checkout.customer,
                            checkout_session: checkout.id,
                            payment_intent: checkout.payment_intent.id,
                            payment_status: checkout.payment_status,
                            amount_subtotal: checkout.amount_subtotal,
                            amount_total: checkout.amount_total,
                            amount_tax: checkout.total_details.amount_tax,
                            amount_shipping: checkout.total_details.amount_shipping,
                            receipt_url: checkout.payment_intent.latest_charge.receipt_url,
                            stripe_fee: checkout.payment_intent.latest_charge.balance_transaction.fee
                          }
                          order.update(properties: properties)
                        else
                          @logger_namespace.api_resources.create!(properties: {
                            response: printify_order.body,
                            order_id: order.id,
                            request_body: req_body,
                            request_url: "\#{printify_base_url}.json",
                            timestamp: Time.zone.now
                          })
                          raise "Printify order creation failed"
                        end
                      end
                    end
                    
                    FulfillOrder  
                    RUBY
)

WebhookVerificationMethod.create(webhook_type: 'stripe', external_api_client_id: fulfill_order_plugin.id, webhook_secret: '')

cleanup_unprocessed_orders_plugin = orders_namespace.external_api_clients.create(
  label: "clean_unprocessed_orders",
  enabled: true,
  drive_strategy: "cron",
  drive_every: 'one_day',
  metadata: {
    LOGGER_NAMESPACE: "order_cleanup_logs",
  },
  model_definition: <<~RUBY
                    class CleanUnprocessedOrders
                      def initialize(parameters)
                        @external_api_client = parameters[:external_api_client]
                        @logger_namespace = ApiNamespace.find_by(slug: @external_api_client.metadata["LOGGER_NAMESPACE"])
                    
                        @buffer_time = 1.hour
                        @start_date_time = Time.zone.now.beginning_of_day - @buffer_time
                        @end_date_time = Time.zone.now - @buffer_time
                      end
                      
                      def start
                        begin
                          ApiResource.transaction do
                            @logger = @logger_namespace.api_resources.create!(
                              properties: {
                                'source' => 'clean_unprocessed_orders',
                                'start_time' => @start_date_time.to_s,
                                'end_time' => @end_date_time.to_s
                              }
                            )
                    
                            orders_to_be_deleted = @external_api_client
                                                    .api_namespace
                                                    .api_resources
                                                    .where(created_at: @start_date_time..@end_date_time)
                                                    .jsonb_search(:properties, { printify_status: 'initialized' })
                                                    .order(:created_at)
                            initial_size = orders_to_be_deleted.size
                    
                            @logger.properties['before_cleanup_orders'] = orders_to_be_deleted.pluck(:id)
                            @logger.properties['cleanup_status'] = 'initialized'
                            @logger.save!
                    
                            orders_to_be_deleted.each do |orphan_order|
                              orphan_order.destroy!
                            end
                    
                            orders_to_be_deleted.reload
                            final_size = orders_to_be_deleted.size
                    
                            if final_size.zero?
                              @logger.properties['cleanup_status'] = 'completed'
                            else
                              @logger.properties['cleanup_status'] = 'partially_deleted'
                              @logger.properties['after_cleanup_remaining_orders'] = orders_to_be_deleted.pluck(:id)
                            end
                    
                            @logger.save!
                          end
                        rescue => e
                          @logger.properties['cleanup_status'] = 'failed'
                          @logger.properties['error_message'] = e.message
                          @logger.properties['error_backtrace'] = e.backtrace.join("\n")
                          @logger.save!
                        end
                      end
                    end
                    
                    CleanUnprocessedOrders
                    RUBY
)

clean_unprocessed_orders_manually_plugin = orders_namespace.external_api_clients.create(
  label: "clean_unprocessed_orders_manually",
  enabled: true,
  drive_strategy: "on_demand",
  metadata: {
    LOGGER_NAMESPACE: "order_cleanup_logs",
    START_TIME: "",
    END_TIME: ""
  },
  model_definition: <<~RUBY
                    class CleanUnprocessedOrdersManually
                      def initialize(parameters)
                        @external_api_client = parameters[:external_api_client]
                        @logger_namespace = ApiNamespace.find_by(slug: @external_api_client.metadata["LOGGER_NAMESPACE"])
                    
                        @start_date_time = DateTime.parse(@external_api_client.metadata['START_TIME'])
                        @end_date_time = DateTime.parse(@external_api_client.metadata['END_TIME']) || Time.zone.now
                      end
                      
                      def start
                        begin
                          ApiResource.transaction do
                            @logger = @logger_namespace.api_resources.create!(
                              properties: {
                                'source' => 'clean_unprocessed_orders_manually',
                                'start_time' => @start_date_time.to_s,
                                'end_time' => @end_date_time.to_s
                              }
                            )
                    
                            orders_to_be_deleted = @external_api_client
                                                    .api_namespace
                                                    .api_resources
                                                    .where(created_at: @start_date_time..@end_date_time)
                                                    .jsonb_search(:properties, { printify_status: 'initialized' })
                                                    .order(:created_at)
                            initial_size = orders_to_be_deleted.size
                    
                            @logger.properties['before_cleanup_orders'] = orders_to_be_deleted.pluck(:id)
                            @logger.properties['cleanup_status'] = 'initialized'
                            @logger.save!
                    
                            orders_to_be_deleted.each do |orphan_order|
                              orphan_order.destroy!
                            end
                    
                            orders_to_be_deleted.reload
                            final_size = orders_to_be_deleted.size
                    
                            if final_size.zero?
                              @logger.properties['cleanup_status'] = 'completed'
                            else
                              @logger.properties['cleanup_status'] = 'partially_deleted'
                              @logger.properties['after_cleanup_remaining_orders'] = orders_to_be_deleted.pluck(:id)
                            end
                    
                            @logger.save!
                          end
                        rescue => e
                          @logger.properties['cleanup_status'] = 'failed'
                          @logger.properties['error_message'] = e.message
                          @logger.properties['error_backtrace'] = e.backtrace.join("\n")
                          @logger.save!
                        end
                      end
                    end
                    
                    CleanUnprocessedOrdersManually
                    RUBY
)

order_status_notification_plugin = orders_namespace.external_api_clients.create(
  label: "order_status_notification",
  enabled: true,
  drive_strategy: "webhook",
  metadata: {
    LOGGER_NAMESPACE: "shop_logs",
    NOTIFICATION_NAMESPACE: "notifications"
  },
  model_definition: <<~RUBY
                    # This connection receives updated order status from Printify and creates/updates a notification API resource
                    class OrderStatusNotification
                      def initialize(parameters)
                        @external_api_client = parameters[:external_api_client]
                        @metadata = @external_api_client.metadata
                        @payload = parameters[:request]&.request_parameters
                    
                        @notification_namespace = ApiNamespace.find_by(slug: @metadata['NOTIFICATION_NAMESPACE'])
                        @logger_namespace = ApiNamespace.find_by(slug: @metadata['LOGGER_NAMESPACE'])
                        @order = @external_api_client.api_namespace.api_resources.where("properties @> ?", {printify_order_id: @payload['resource']['id']}.to_json).first
                      end
                      
                      def start
                        begin
                          if @order.nil?
                            log_error "An order with the provided ID could not be found"
                            render json: {
                              success: false,
                              message: "An order with the provided ID could not be found"
                            }
                          else
                            @shop = @order.shop
                            order_id = @order.properties['printify_order_id']
                    
                            # Only "canceled" order production status is considered if there is an order production status
                            if @payload['resource']['data']['status'].nil? || @payload['resource']['data']['status'] == "canceled"
                              # If there is a status update for an existing order, then its final_printify_order_status will change
                              # For a new order, the initial and final order status will be the same
                              notification_for_existing_order = @notification_namespace.api_resources.where("properties @> ?", {printify_order_id: order_id}.to_json).first
                              passed_processing_fee_to_customer = @order.properties['passed_processing_fee_to_customer']
                              sales_tax_collected = @order.properties['sales_tax_collected']
                              stripe = @order.properties['stripe']
                              total_retail_price = @order.properties['passed_processing_fee_to_customer'] ? (stripe['amount_subtotal'] - @order.properties['stripe_processing_fee']) : stripe['amount_subtotal']
                    
                              notification_data = {
                                line_items: @order.properties['line_items'],
                                address_to: @order.properties['address_to'],
                                email_subject: get_email_subject,
                                price_info: {
                                  total_retail_price: get_formatted_price(total_retail_price),
                                  total_shipping: get_formatted_price(stripe['amount_shipping']),
                                  total_tax: get_formatted_price(sales_tax_collected ? stripe['amount_tax'] : 0),
                                  convenience_fee: get_formatted_price(passed_processing_fee_to_customer ? @order.properties['stripe_processing_fee'] : 0),
                                  total_price: get_formatted_price(stripe['amount_total'])
                                },
                                printify_shop_id: @payload['resource']['data']['shop_id'],
                                printify_order_id: order_id,
                                order_id: @order.id,
                                stripe_receipt_url: stripe['receipt_url'],
                                stripe_refund_status: @order.properties['stripe_refund_status'],
                                final_printify_order_status: get_new_order_status,
                                initial_printify_order_status: notification_for_existing_order ? notification_for_existing_order.properties['initial_printify_order_status'] : get_new_order_status
                              }
                              if @payload['type'].start_with?("order:shipment:")
                                notification_data[:carrier] = @payload['resource']['data']['carrier']
                              end
                              @notification_namespace.api_resources.create!(properties: notification_data)
                              render json: { success: true }
                            end
                          end  
                        rescue => e
                          log_error(e.message, { error_backtrace: e.backtrace })
                          render json: { success: false }
                        end 		
                      end
                          
                      def get_new_order_status 
                        orderStatusMap = {
                          "order:created" => "created",
                          "order:sent-to-production" => "sent to production",
                          "order:shipment:created" => "shipped",
                          "order:shipment:delivered" => "delivered"
                        }
                        
                        if @payload['resource']['data']['status'] == "canceled"
                          "canceled"
                        else
                          orderStatusMap[@payload['type']]
                        end
                      end
                      
                      def get_email_subject
                        order_id = @order.properties['printify_order_id']
                        orderStatusMap = {
                          "order:created" => "\#{ENV['APP_HOST']} Confirmation for order \#{order_id}",
                          "order:sent-to-production" => "\#{ENV['APP_HOST']} Order \#{order_id} sent to production",
                          "order:shipment:created" => "\#{ENV['APP_HOST']} Order \#{order_id} is on the way",
                          "order:shipment:delivered" => "\#{ENV['APP_HOST']} Order \#{order_id} has been delivered"
                        }
                        
                        if @payload['resource']['data']['status'] == "canceled"
                          "\#{ENV['APP_HOST']} Confirmation for order \#{order_id} cancellation"
                        else
                          orderStatusMap[@payload['type']]
                        end
                      end
                      
                      def get_formatted_price(price)
                        {
                          value: price.to_f / 100,
                          text: "$\#{price.to_f / 100} \#{@shop.properties['currency']}"
                        }
                      end
                    
                      def log_error(message, extra = {})
                        @logger_namespace.api_resources.create!(properties: {
                          status: 'error',
                          source: 'order_status',
                          request_body: @payload,                                      
                          error: message,
                          timestamp: Time.zone.now,
                          order_id: @order&.id,
                          extra: extra
                        })
                      end
                    end
                    
                    OrderStatusNotification
                    RUBY
)


p "###################################       SECURING PRINTIFY ORDER STATUS CHANGE WEBHOOK       ###################################"
            
WebhookVerificationMethod.create(
  webhook_type: 'custom',
  external_api_client_id: order_status_notification_plugin.id,
  webhook_secret: WEBHOOK_SECRET,
  custom_method_definition: <<~RUBY
                            hex_digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), verification_method.webhook_secret.encode('utf-8'), request.body.string.encode('utf-8'))
                            signature = request.headers['X-Pfy-Signature'] || ''
                            if ActiveSupport::SecurityUtils.secure_compare(signature, "sha256=\#{hex_digest}")
                              [true, 'Success']
                            else
                              [false, 'Verification failed']
                            end
                            RUBY

)


p "###################################               CREATE NOTIFICATIONS NAMESPACE              ###################################"

notifications_namespace = ApiNamespace.create(
  name: 'notifications',
  version: 1,
  requires_authentication: true,
  properties: {
    carrier: {},
    address_to: {},
    line_items: [],
    price_info: {},
    email_subject: "",
    printify_shop_id: "",
    printify_order_id: "",
    stripe_refund_status: "",
    final_printify_order_status: "",
    initial_printify_order_status: ""
  },
  associations: [{type: 'belongs_to', namespace: 'orders'}],
  category_ids: [namespace_category.id]
)

p "###################################              CREATE ORDER EMAIL NOTIFICATIONS             ###################################"

notifications_namespace.api_actions.create(
  action_type: "send_email",
  include_api_resource_data: false,
  email: "\#{api_resource.properties['address_to']['email']}",
  email_subject: "\#{api_resource.properties['email_subject']}",
  type: "CreateApiAction",
  custom_message: <<~HTML
                  <% price_info = api_resource.properties['price_info'] %>
                  <% address_to = api_resource.properties['address_to'] %>
                  <% carrier = api_resource.properties['carrier'] %>
                  Hi <%= address_to['first_name'] + " " + address_to['last_name'] %>,
                  <% case api_resource.properties['final_printify_order_status'] when 'created' %>
                  Thank you for shopping at <%= ENV['APP_HOST'] %>! We have received your order.
                  <% when 'sent to production' %>
                  Thank you for shopping at <%= ENV['APP_HOST'] %>! Your order has been sent to production.
                  <% when 'shipped' %>
                  Thank you for shopping at <%= ENV['APP_HOST'] %>! We have shipped your order.
                  
                  Tracking information
                  Carrier: <%= carrier['code'] %>
                  Tracking number: <%= carrier['tracking_number'] %>
                  Tracking URL: <%= carrier['tracking_url'] %>
                  <% when 'delivered' %>
                  Thank you for shopping at <%= ENV['APP_HOST'] %>! Your order has been delivered to your shipping address.
                  
                  Tracking information
                  Carrier: <%= carrier['code'] %>
                  Tracking number: <%= carrier['tracking_number'] %>
                  Tracking URL: <%= carrier['tracking_url'] %>
                  <% when 'canceled' %>
                  Your order has been canceled.
                  <% end %>
                  
                  Order Summary
                  Order ID: <%= api_resource.properties['printify_order_id'] %>
                  Receipt URL: <%= api_resource.properties['stripe_receipt_url'] %>
                  Items:
                  <% api_resource.properties['line_items'].each do |item| %>
                  <%= item['quantity'].to_s + "x " + item['metadata']['variant_label'] + " " + item['metadata']['title'] %>
                  <% end %>
                  Subtotal: <%= price_info['total_retail_price']['text'] %>
                  Shipping cost: <%= price_info['total_shipping']['text'] %>
                  <%= price_info['total_tax']['value'] > 0 ? 'Tax: ' + price_info['total_tax']['text'] : "" %>
                  <%= price_info['convenience_fee']['value'] > 0 ? 'Convenience fee: ' + price_info['convenience_fee']['text'] : "" %>
                  Total: <%= price_info['total_price']['text'] %>
                  <% if api_resource.properties['final_printify_order_status'] != 'canceled' %>
                  Shipping Address
                  <%= address_to['first_name'] + " " + address_to['last_name'] %>
                  <%= address_to['address1'] %>
                  <%= address_to['city'] %>
                  <%= address_to['region'] + " " + address_to['zip'] %>
                  <%= address_to['country'] %>
                  <% end %>
                  HTML
)


p "###################################             CREATE ORDER CLEANUP LOGS NAMESPACE           ###################################"

order_cleanup_logs_namespace = ApiNamespace.create(
  name: 'order_cleanup_logs',
  version: 1,
  requires_authentication: true,
  properties: {
    source: "",
    end_time: "",
    start_time: "",
    error_message: "",
    cleanup_status: "",
    error_backtrace: "",
    before_cleanup_orders: [],
    after_cleanup_remaining_orders: []
  },
  associations: [{type: 'belongs_to', namespace: 'orders'}],
  category_ids: [namespace_category.id]
)


p "###################################                  CREATING PRINFIFY SHOP UI                ###################################"

layout_content =  <<~HTML
                  <script src="https://js.stripe.com/v3/"></script>
                  {{cms:snippet navbar-custom-shop}}
                  {{cms:wysiwyg content}}
                  HTML

layout_css =  <<~CSS
              *,
              *::before,
              *::after {
                margin: 0;
                padding: 0;
                box-sizing: inherit;
              }

              :root {
                --max-container-width: 1300px;
                --max-product-image-width: 350px;
                
                /* Colors */
                --color-gray: gray;
                --color-black: #1a1a1a;
                
                /* Typography */
                --gray-text: var(--color-gray);
                --default-text: var(--color-black);
                
                /* Carousel Indicator colors */
                --default-indicator: hsl(26, 11%, 62%);
                --active-indicator: var(--color-black);
                
                --slide-transition-duration: 500ms;
                --image-border: 1px solid hsl(208, 13%, 45%);
              }

              html {
                box-sizing: border-box;
              }

              body {
                color: var(--default-text);
              }

              .cart-link {
                position: relative;
              }

              .cart-link svg {
                width: 30px;
                height: 30px;
              }

              .cart-item-count {
                display: flex;
                justify-content: center;
                align-items: center;
                position: absolute;
                top: -6px;
                left: -10px;
                width: 20px;
                height: 20px;
                padding: 11px;
                color: #fff;
                font-size: 13px;
                border-radius: 20px;
                background-color: red; 
              }

              .product__link-wrapper,
              .product__link-wrapper:hover,
              .product__link-wrapper:visited,
              .product__link-wrapper:active {
                color: var(--default-text);
              }

              .product__link-wrapper:hover {
                text-decoration: none;
              }

              .product__image {
                width: 100%;
                border-radius: 8px;
                border: var(--image-border); 
              }

              .product__category {
                margin-bottom: 8px;
                color: hsla(208, 13%, 45%, 1);
              }

              .product__price {
                display: flex;
              }

              .product__price data {
                margin-left: 5px;
                font-weight: 600;
              }

              /* Utilities */
              .restrictive-container {
                width: 89%;
                max-width: var(--max-container-width);
                margin-left: auto;
                margin-right: auto;
              }
              .section {
                padding-top: 40px;
                padding-bottom: 40px;
              }
              .section__subtitle {
                margin-bottom: 30px;
              }
              .opacity-0 {
                opacity: 0;
              }
              /* Best-selling-items */
              .best-selling-items {
                text-align: center;
              }
              .best-selling-items__carousel-container {
                display: grid;
                align-items: center;
                gap: 30px;
              }
              .best-selling-items__section-subtitle {
                margin-bottom: 4px;
              }
              .best-selling-items__section-title {
                margin-bottom: 30px;
              }
              .best-selling-items .product__price {
                justify-content: center;
              }
              /* Single-item carousel */
              .single-item-carousel {
                display: flex;
                align-items: center;
              }
              .single-item-carousel__middle-container {
                flex-grow: 1;
              }
              .single-item-carousel__slides {
                position: relative;
                overflow: hidden;
                height: 450px;
                margin: 0 10px;
              }
              .single-item-carousel__slide {
                position: absolute;
                width: 100%;
                transition: transform var(--slide-transition-duration) ease-in-out;
              }
              .single-item-carousel__slide img {
                width: 100%;
              }
              .single-item-carousel__arrow {
                border: none;
                background-color: transparent;
              }
              .single-item-carousel__arrow svg {
                width: 20px;
                height: 20px;
              }
              .single-item-carousel__indicators {
                display: flex;
                flex-wrap: wrap;
                justify-content: center;
                margin-top: 30px;
              }
              .single-item-carousel__indicator {
                width: 10px;
                height: 10px;
                margin-bottom: 10px;
                border: none;
                border-radius: 50%;
                background-color: var(--default-indicator);
              }
              .single-item-carousel__indicator:not(:last-child) {
                margin-right: 10px;
              }
              .single-item-carousel__indicator--active {
                background-color: var(--active-indicator);
              }
              /* Multi-item Carousel */
              .multi-item-carousel__slides {
                position: relative;
                height: 450px;
                overflow: hidden;
              }
              .multi-item-carousel__slide {
                position: absolute;
                width: 100%;
                transition: transform var(--slide-transition-duration) ease-in-out;
              }
              .multi-item-carousel__slide .product__link-wrapper {
                max-width: var(--max-product-image-width);
              }
              .multi-item-carousel__slide > *:not(:last-child) {
                margin-right: 30px;
              }
              .multi-item-carousel__controls {
                display: flex;
                align-items: center;
                margin-top: 30px;
              }
              .multi-item-carousel__arrow {
                border: 1px solid var(--color-gray);
                border-radius: 4px;
              }
              .multi-item-carousel__indicators {
                display: flex;
                flex-grow: 1;
                margin-right: 20px;
              }
              .multi-item-carousel__indicator {
                border: none;
                height: 3px;
                background-color: var(--default-indicator);
                flex-grow: 1;
              }
              .multi-item-carousel__indicator--active {
                background-color: var(--active-indicator);
              }
              .multi-item-carousel__arrow--prev {
                margin-right: 5px;
              }
              .multi-item-carousel__arrow svg {
                transform: translateY(-2px);
              }
              /* Toast */
              .toast-container {
                position: fixed;
                bottom: 30px;
                left: 30px;
                width: 100%;
                max-width: 350px;
              }
              .shop-toast {
                background-color: #159160;
                border-radius: 4px;
                padding: 15px;
                opacity: 0;
                transition: opacity 0.2s ease-in-out;
              }
              .shop-toast:not(:last-child) {
                margin-bottom: 10px;
              }
              .shop-toast--show {
                opacity: 1;
              }
              .shop-toast__body {
                display: flex;
                justify-content: space-between;
              }
              .shop-toast__body p {
                margin-bottom: 0;
                color: #fff;
              }
              .shop-toast__btn-close {
                border: none;
                background-color: transparent;
                transform: translateY(-2px);
                color: #fff;
              }
              .shop-toast__btn-close span {
                transform: scale(1.5);
              }
              /* Error message */
              .error-message {
                padding: 14px;
                border-radius: 4px;
                background-color: #ffc8c8;
                font-weight: 600;
                font-size: 12px;
                color: #b30022;
              }
              /* Loading spinner */
              .loading-spinner {
                position: absolute;
                top: 50%;
                left: 50%;
                width: 40px;
                height: 40px;
                border-radius: 50%;
                border: 6px solid #f3f3f3;
                border-top: 6px solid #3498db;
                transform: translate(-50%, -50%);
                animation: spin 1s linear infinite;
              }
              @keyframes spin {
                0% {
                  transform: rotate(0deg);
                }
                100% {
                  transform: rotate(360deg);
                }
              }
              /* Media queries */
              @media only screen and (min-width: 700px) {
                .best-selling-items {
                  text-align: left;
                }
                .best-selling-items__carousel-container {
                  grid-template-columns: 1fr 1fr;
                }
                .best-selling-items .single-item-carousel {
                  max-width: 600px;
                }
                .best-selling-items .product__price {
                  justify-content: start;
                }
              }  
              CSS

layout_js = <<~JAVASCRIPT
            async function init() {
              const config = getConfig();
              const cartKey = config["CART_KEY"];
              const cart = getCart();
              // An array of shop detail objects
              let shopDetails = getShopDetails();
              
              if (!cart) {
                const value = {
                  line_items: []
                };
                sessionStorage.setItem(cartKey, JSON.stringify(value));
              }
              
              window.addEventListener("turbo:load", setItemCountInCartIcon);
              
              if (!shopDetails) {
                shopDetails = await getShopDetailsAsync();
                sessionStorage.setItem(config["SHOP_DETAILS_KEY"], JSON.stringify(shopDetails));
              }
            }

            async function getShopDetailsAsync() {
              try {
                const response = await fetch(getConfig()["SHOP_DETAILS_URL"], {
                  method: "POST",
                  headers: {"Content-Type": "application/json"},
                  body: JSON.stringify({})
                });
                if (!response.ok) {
                  throw new Error(getConfig()["ERROR_MESSAGES"]["SHOP_DETAILS"]);
                }
                const { data } = await response.json();
                return data.shops_detail;
              } catch (error) {
                throw(error);
              }
            }

            function getShopDetails() {
              return JSON.parse(sessionStorage.getItem(getConfig()["SHOP_DETAILS_KEY"]));
            }

            function setItemCountInCartIcon() {
              const cart = getCart();
              const cartItemCountElement =  document.querySelector(".cart-item-count");
              const itemCount = cart.line_items.length;
              if (itemCount > 0) {
                cartItemCountElement.textContent = itemCount;
                cartItemCountElement.classList.remove("d-none");
              } else {
                cartItemCountElement.classList.add("d-none");
                cartItemCountElement.textContent = "";
              }
            }

            function getConfig() {
              return {
                CART_KEY: "restaroneCart",
                SHOP_DETAILS_KEY: "restaroneShopDetails",
                TOAST_HIDE_DELAY: 1500,
                ERROR_MESSAGES: {
                  PRICE_DETAILS: "A problem occurred while calculating prices. Please try again later.",
                  CHECKOUT: "A problem occurred while processing checkout request. Please try again later.",
                  SHOP_DETAILS: "Could not get necessary shop details. Please try again later."
                },
                CUSTOM_EVENTS: {
                  VARIANT_CHANGE: "variant-change"
                },
                PRODUCTS_URL: "/api/1/products",
                SHOP_DETAILS_URL: `${window.location.origin}/api/1/shops/shops_detail/webhook`,
                PRICE_DETAILS_URL: `${window.location.origin}/api/1/orders/fetch_printify_shipping_and_stripe_processing_fees/webhook`,
                CHECKOUT_URL: `${window.location.origin}/api/1/orders/create_order_and_stripe_chekout_session/webhook`
              };
            }

            async function getProductsAsync(productIds) {
              const payload = {
                properties: {
                  printify_product_id: {
                    value: productIds,
                    option: "PARTIAL",
                    match: "ANY"
                  }
                }
              }
              const result = await $.ajax({
                url: getConfig()["PRODUCTS_URL"],
                type: "GET",
                data: payload
              });
              return result.data.map(item => item.attributes);
            }

            async function getProductAsync(productId) {
              const payload = {
              properties: {
                printify_product_id: productId
              }
            };
              const result = await $.ajax({
                url: getConfig()["PRODUCTS_URL"],
                type: "GET",
                data: payload
              });
              return result.data[0].attributes;
            }

            function getVariantImage(variantId, images) {
              const frontImage = images.find(image => image.variant_ids.includes(variantId) && image === "front");
              if (frontImage) return frontImage;
              const anyOtherImage = images.find(image => image.variant_ids.includes(variantId));
              if (anyOtherImage) return anyOtherImage;
              // If there is no image at all for the particular variant, then return the default image
              return images.find(image => image.is_default);
            }

            function getCart() {
              const cartKey = getConfig()["CART_KEY"];
              return JSON.parse(sessionStorage.getItem(cartKey));
            }

            function setCart(value) {
              const cartKey = getConfig()["CART_KEY"];
              sessionStorage.setItem(cartKey, JSON.stringify(value));
            }

            function getFormattedPrice(price) {
              return {
                value: price / 100,
                text: `\$${(price / 100).toFixed(2)}`
              };
            }

            function debounce(callback, delay) {
              let timer;
              return function(...args) {
                clearTimeout(timer);
                timer = setTimeout(function() {
                  callback(...args);
                }, delay);
              }
            }

            function showElement(selector) {
              const element = document.querySelector(selector);
              element.classList.remove("d-none");
            }

            function hideElement(selector) {
              const element = document.querySelector(selector);
              element.classList.add("d-none");
            }

            function initToast(toastContainer, toastText) {
              // Remove all hidden toasts
              const hiddenToasts = document.querySelectorAll(".shop-toast:not(.shop-toast--show)");
              hiddenToasts.forEach(toast => toast.remove());
              
              // Create toast markup
              const markup = `
                <div aria-live="polite" role="status" aria-atomic="true" class="shop-toast">
                  <div class="shop-toast__body">
                    <p class="shop-toast__message">${toastText}</p>
                    <button type="button" class="shop-toast__btn-close" data-dismiss="toast" aria-label="Close">
                      <span aria-hidden="true">&times;</span>
                    </button>
                  </div>
                </div>
              `;
              // Insert toast into the toast container
              toastContainer.insertAdjacentHTML("afterBegin", markup);
              
              const toast = toastContainer.firstElementChild;
              const closeButton = toast.querySelector(".shop-toast__btn-close");
              
              closeButton.addEventListener("click", function() {
                toast.classList.remove("shop-toast--show");
              });
              
              // Show toast
              toast.classList.add("shop-toast--show");
              
              // Set a timer for hiding the toast
              setTimeout(function () {
                toast.classList.remove("shop-toast--show");
              }, getConfig()["TOAST_HIDE_DELAY"]);
            }

            function initCarousel(carouselConfig) {
              const { carouselType, parentContainer, callback, callbackArgs } = carouselConfig;
              const carousel = parentContainer ? parentContainer.querySelector(`.${carouselType}`) : document.querySelector(`.${carouselType}`);
              
              const slides = carousel.querySelectorAll(`.${carouselType}__slide`);
              const slidesContainer = carousel.querySelector(`.${carouselType}__slides`);
              const indicators = carousel.querySelectorAll(`.${carouselType}__indicator`);
              const indicatorsContainer = carousel.querySelector(`.${carouselType}__indicators`);
              const nextButton = carousel.querySelector(`.${carouselType}__arrow--next`);
              const previousButton = carousel.querySelector(`.${carouselType}__arrow--prev`);
              const variantChangeEventName = getConfig()["CUSTOM_EVENTS"]["VARIANT_CHANGE"]; 
              let currentSlideIndex = 0;
              
              const setHeightOfSlidesContainerDebounced = debounce(setHeightOfSlidesContainer, 100);
              
              carousel.setAttribute("data-current-slide-index", currentSlideIndex);
              
              const resizeObserver = new ResizeObserver(function (entries) {
                setHeightOfSlidesContainerDebounced();
              });
              
              resizeObserver.observe(slidesContainer);
              
              carousel.addEventListener(variantChangeEventName, function(e) {
                const newSlideIndex = Number.parseFloat(e.detail);
                currentSlideIndex = newSlideIndex;
                carousel.setAttribute("data-current-slide-index", currentSlideIndex);
                positionSlides(currentSlideIndex, slides);
                setActiveIndicator();
              });
              nextButton.addEventListener("click", function() {
                handleClickNextSlide();  
              });
              previousButton.addEventListener("click", function() {
                handleClickPreviousSlide();  
              });
              indicatorsContainer.addEventListener("click", handleClickIndicator);
              
              showLoadingSpinner(carousel);
              positionSlides();
              setActiveIndicator();
              // the loading state will end when the height of carousel has been set
              setHeightOfSlidesContainer();
              
              function positionSlides() {
                slides.forEach((slide, i) => {
                  slide.style.transform = `translateX(${(i - currentSlideIndex) * 100}%)`;
                });
              }
              
              function handleClickNextSlide() {
                // If current slide is the last one, then go back to the first slide
                if (currentSlideIndex === slides.length - 1) currentSlideIndex = 0;
                else currentSlideIndex++;
                carousel.setAttribute("data-current-slide-index", currentSlideIndex);
                positionSlides(currentSlideIndex, slides);
                setActiveIndicator();
              }
              
              function handleClickPreviousSlide() {
                // If current slide is the first one, then go back to the last slide
                if (currentSlideIndex === 0) currentSlideIndex = slides.length - 1;
                else currentSlideIndex--;
                carousel.setAttribute("data-current-slide-index", currentSlideIndex);
                positionSlides(currentSlideIndex, slides);
                setActiveIndicator();
              }
              
              function handleClickIndicator(e) {
                const clickedIndicator = e.target.closest(`.${carouselType}__indicator`);
                if (!clickedIndicator) return;
                currentSlideIndex = Number.parseFloat(clickedIndicator.dataset.slideIndex);
                carousel.setAttribute("data-current-slide-index", currentSlideIndex);
                positionSlides(currentSlideIndex, slides);
                setActiveIndicator();
              }
              
              function setActiveIndicator() {
                indicators.forEach(indicator => indicator.classList.remove(`${carouselType}__indicator--active`));
                const currentIndicator = carousel.querySelector(`.${carouselType}__indicators [data-slide-index="${currentSlideIndex}"]`);
                currentIndicator.classList.add(`${carouselType}__indicator--active`);
              }
              
              function setHeightOfSlidesContainer() {
                const firstImage = slidesContainer.querySelector(`.${carouselType}__slide:first-of-type img`);
                let maxHeight = -Infinity;
                // If a carousel has a display of none, then it should have the default height set in CSS
                if (slidesContainer.offsetHeight === 0) return;
                
                slides.forEach(slide => {
                  maxHeight = Math.max(maxHeight, slide.offsetHeight);
                });
                
                // Check if the height has been calculated properly based on whether or not the first image has loaded
                // So, set another timer to wait further and recalculate height
                // window load event is not fired on Turbo link visit; that's why this strategy is required
                if (!firstImage.complete) {
                  setTimeout(setHeightOfSlidesContainer, 200);
                  return;
                }
                slidesContainer.style.height = `${maxHeight}px`;
                
                // The callback (if any) is called at this stage to make sure that it is executed only after the carousel has been set up properly
                // It is called before removing loading state because it can contain code that modifies the carousel
                if (callback) callback(...callbackArgs);
                
                // This timer will account for transition duration for slides
                // The loading state should end when the transition of slides has ended
                setTimeout(function() {
                  removeLoadingSpinner(carousel);
                }, 500);
              }
            }

            function initBestSellingItemsCarousel() {
              const carouselConfig = {
                carouselType: "single-item-carousel",
                parentContainer: document.querySelector(".best-selling-items__carousel-container")
              };

              initCarousel(carouselConfig);

              const bestSellingItemsCarousel = document.querySelector(".best-selling-items .single-item-carousel");
              const bestSellingItemsInfoContainers = document.querySelectorAll(".best-selling-items__info");
              const nextButton = bestSellingItemsCarousel.querySelector(".single-item-carousel__arrow--next");
              const prevButton = bestSellingItemsCarousel.querySelector(".single-item-carousel__arrow--prev");
              const indicatorsContainer = bestSellingItemsCarousel.querySelector(".single-item-carousel__indicators");

              nextButton.addEventListener("click", changeBestSellingItemsInfo);
              prevButton.addEventListener("click", changeBestSellingItemsInfo);
              indicatorsContainer.addEventListener("click", changeBestSellingItemsInfo);

              function changeBestSellingItemsInfo(e) {
                const carouselControl = e.target.closest(".single-item-carousel__arrow, .single-item-carousel__indicator");
                if (!carouselControl) return;

              bestSellingItemsInfoContainers.forEach(infoContainer => {
                const infoSlideIndex = Number.parseFloat(infoContainer.dataset.slideIndex);
                const currentSlideIndex = Number.parseFloat(bestSellingItemsCarousel.dataset.currentSlideIndex);
                if (infoSlideIndex === currentSlideIndex) infoContainer.classList.remove("d-none");
                else infoContainer.classList.add("d-none");
              });
              }
            }

            function showLoadingSpinner(container) {
              const markup = `
                <span class="loading-spinner"></span>
              `;
              container.classList.add("position-relative");
              container.insertAdjacentHTML("afterbegin", markup);
            }

            function removeLoadingSpinner(container) {
              const spinner = container.querySelector(".loading-spinner");
              if (!spinner) return;
              spinner.remove();
              container.classList.remove("position-relative");
              [...container.children].forEach(child => child.classList.remove("opacity-0"));
            }

            init();
            JAVASCRIPT

layout = site.layouts.create(
  label: 'printify-shop',
  identifier: 'printify-shop',
  app_layout: 'website',
  content: layout_content,
  css: layout_css,
  js: layout_js,
  category_ids: [layout_category.id]
)

site.snippets.create(
  label: 'products', 
  identifier: 'products',
  category_ids: [snippet_category.id],
  content:  <<~HTML
            <% @api_resources.each do |resource| %>
              <% min_price = 1000000 %>
              <% resource.properties['variants'].each do |variant| %>
                <% if variant['price'] < min_price %>
                  <% min_price = variant['price'] %>
                <% end %>
              <% end %>
              <a class="product__link-wrapper" href="/product-details?id=<%= resource.id %>">
                <article class="product">
                  <img class="product__image" src="<%= resource.properties['default_image_url'] %>" alt="<%= resource.properties['title'] %>">
                  <p class="product__category">
                    <%= resource.properties['sub_categories'].empty? ? resource.properties['categories'][0] : resource.properties['sub_categories'][0] %>
                  </p>
                  <div class="product__info">
                    <h3 class="product__title">
                      <%= resource.properties['title'] %>
                    </h3>
                    <p class="product__price">
                      From
                      <data value="<%= min_price.to_f / 100 %>">
                          $<%= min_price.to_f / 100 %>  
                      </data>
                    </p>
                  </div>
                </article>
              </a>  
            <% end %>
            HTML
)

site.snippets.create(
  label: 'products-show', 
  identifier: 'products-show',
  category_ids: [snippet_category.id],
  content:  <<~HTML
            <% enabled_variants = @api_resource.properties['variants'].filter {|variant| variant['is_enabled']} %>
            <% default_variant = enabled_variants.find{|variant| variant['is_default']} || enabled_variants.first %>
            <article class="product" data-product-id="<%= @api_resource.properties['printify_product_id'] %>">
              <div class="single-item-carousel">
                <button class="single-item-carousel__arrow single-item-carousel__arrow--prev opacity-0">
                  {{ cms:snippet carousel-control-prev-icon }}
                </button>
                <div class="single-item-carousel__middle-container opacity-0">
                  <div class="single-item-carousel__slides">
                    <% @api_resource.properties['images'].each_with_index do |image, i| %>
                      <div class="single-item-carousel__slide" data-slide-index="<%= i %>" data-variant-ids="<%= image['variant_ids'] %>" data-image-position="<%= image['position'] %>" data-is-default-image="<%= image['is_default'] %>">
                        <img class="product__image" src="<%= image['src'] %>" alt="<%= @api_resource.properties['title'] %>">
                      </div>
                    <% end %>
                  </div>
                  <div class="single-item-carousel__indicators">
                    <% @api_resource.properties['images'].each_with_index do |image, i| %>
                      <button class="single-item-carousel__indicator" aria-label="Go to slide <%= i + 1 %>" data-slide-index="<%= i %>"></button>
                    <% end %>
                  </div>
                </div>   
                <button class="single-item-carousel__arrow single-item-carousel__arrow--next opacity-0">
                  {{ cms:snippet carousel-control-next-icon }}
                </button>
              </div>
              <div class="product__info">
                <p class="product__variant-title">
                  <%= default_variant['title'] %>
                </p>
                <div class="d-flex justify-content-between">
                  <h1 class="product__title">
                    <%= @api_resource.properties['title'] %>
                  </h1>
                  <data class="product__variant-price" value="<%= @api_resource.properties['variants'][0]['price'].to_f / 100 %>">
                    $<%= default_variant['price'].to_f / 100 %>  
                  </data>
                </div>
                <p class="product__variant-availability">
                  <%= default_variant['is_available'] ? 'In stock' : 'Not in stock' %>
                </p>    
                <form class="options-form">
                  <% enabled_options = enabled_variants.map {|variant| variant['options']}.flatten.uniq %>
                  <% @api_resource.properties['options'].each do |option| %>
                    <fieldset class="options-container options-<%= option['type']%>-container">
                      <legend>
                        <%= option['type'].capitalize %>
                      </legend>
                      <div class="options">
                        <% available_option_values = option['values'].filter { |value| enabled_options.include?(value['id'])  } %>
                        <% available_option_values.each do |value| %>
                        <div class="option option--<%= option['type'] %>" data-available-options="<%= value['available_options'] %>" >
                          <% if default_variant['options'].any? {|option_id| option_id == value['id']} %>
                            <input type="radio" name="<%= option['type'] %>" id="<%= value['title'] %>" value="<%= value['title'] %>" data-option-id="<%= value['id'] %>" checked>
                          <% else %>
                            <input type="radio" name="<%= option['type'] %>" id="<%= value['title'] %>" value="<%= value['title'] %>" data-option-id="<%= value['id'] %>">
                          <% end %>
                          <% if option['type'] == 'color' %>
                            <label for="<%= value['title'] %>" style="background-color: <%= value['colors'][0] %>;">
                            <span class="sr-only"><%= value['title'] %></span>
                            </label>
                          <% else %>
                            <label for="<%= value['title'] %>"><%= value['title'] %></label>
                          <% end %>
                        </div>
                        <% end %>
                      </div>
                    </fieldset>
                  <% end %>
                  <div class="product__buttons-container">
                    <button class="btn btn-light btn--add-to-cart" type="submit" <%= !default_variant['is_available'] ? "disabled" : "" %>>
                      Add To Cart
                    </button>
                    <button type="button" class="btn btn-primary btn--buy-now" <%= !default_variant['is_available'] ? "disabled" : "" %>>
                      Buy Now
                    </button>
                  </div>
                </form>    
                <div class="product__description">
                  <h2>
                    Product description
                  </h2>
                  <p>
                    <%= @api_resource.properties['description'] %>
                  </p>
                </div>             
              </div> 
            </article>
            <% similar_products = @api_namespace.api_resources.reject {|resource| !resource.properties['visible'] || resource.properties['printify_product_id'] == @api_resource.properties['printify_product_id'] || (Array.wrap(resource.properties['sub_categories']) & Array.wrap(@api_resource.properties['sub_categories'])).empty?} %>
            <% unless similar_products.empty? %>
              <section class="similar-products-section">
              <h2 class="similar-products-section__title">
                View similar products
              </h2>
              <div class="similar-products">
                <% similar_products.each do |product| %>
                  <a class="similar-products__link" href="/product-details?id=<%= product.id %>">
                    <img src="<%= product.properties['default_image_url'] %>" alt="<%= product.properties['default_image_url'] %>">
                  </a>
                <% end %>  
              </div>
            </section> 
            <% end %>               
            <a href="/custom-shop">Back to Shop page</a>
            HTML
)


site.snippets.create(
  label: "navbar-custom-shop", 
  identifier: "navbar-custom-shop",
  category_ids: [snippet_category.id],
  content:  <<~HTML
            <nav class="navbar navbar-expand-lg navbar-light bg-light">
              <a class="navbar-brand" href="/">Home</a>
              <div class="order-lg-3">
                <a class="cart-link" href="/cart" aria-label="View cart">
                  {{ cms:snippet cart-icon }}
                  <span class="cart-item-count d-none"></span>
                </a>
                <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
                  <span class="navbar-toggler-icon"></span>
                </button>
              </div>
              <div class="collapse navbar-collapse" id="navbarSupportedContent">
                <ul class="navbar-nav mr-auto">
                  <li class="nav-item active">
                    <a class="nav-link" href="#" data-violet-track-click="true" data-violet-event-name="web/navbar/home" data-violet-event-label="Home Page">Home <span class="sr-only">(current)</span></a>
                  </li>
                        <li class="nav-item">
                    <a class="nav-link" href="/custom-shop" data-violet-track-click="true" data-violet-event-name="web/navbar/shop-page" data-violet-event-label="Shop Page">Shop</a>
                  </li>
                  {{ cms:helper logged_in_user_render, admin-controls }}
                </ul>
              </div>
            </nav>
            HTML
)

site.snippets.create(
  label: "products-multi-item-carousel", 
  identifier: "products-multi-item-carousel",
  category_ids: [snippet_category.id],
  content:  <<~HTML
            <div class="d-sm-none">
            <div class="multi-item-carousel">
            <% items_per_slide = 1 %>
            <% total_slides = (@api_resources.count.to_f / items_per_slide).ceil %>
            <% item_index = 0 %>
            <div class="multi-item-carousel__slides opacity-0">
              
            <% total_slides.times do |i| %>
              <% items_added = 0 %>
              <div class="multi-item-carousel__slide" data-slide-index="<%= i %>">
                <% while item_index < @api_resources.count && items_added < items_per_slide %>
                  <% resource = @api_resources[item_index] %>
                  <% min_price = 1000000 %>
                  <% resource.properties['variants'].each do |variant| %>
                    <% if variant['price'] < min_price %>
                      <% min_price = variant['price'] %>
                    <% end %>
                  <% end %>
                  <% item_index += 1 %>
                  <% items_added += 1 %>
                  <a class="product__link-wrapper" href="/product-details?id=<%= resource.id %>">
                    <article class="product">
                      <img class="product__image" src="<%= resource.properties['default_image_url'] %>" alt="<%= resource.properties['title'] %>">
                      <p class="product__category">
                        <%= resource.properties['sub_categories'].empty? ? resource.properties['categories'][0] : resource.properties['sub_categories'][0] %>
                      </p>
                      <div class="product__info">
                        <h3 class="product__title">
                          <%= resource.properties['title'] %>
                        </h3>
                        <p class="product__price">
                          From
                          <data value="<%= min_price.to_f / 100 %>">
                            $<%= min_price.to_f / 100 %>  
                          </data>
                        </p>
                      </div>
                    </article>
                  </a> 
                <% end %>
              </div>
            <% end %>
            </div>
                    
            <div class="multi-item-carousel__controls opacity-0">
              <div class="multi-item-carousel__indicators">
                <% total_slides.times do |i| %>
                  <button class="multi-item-carousel__indicator" aria-label="Go to slide <%= i + 1 %>" data-slide-index="<%= i %>">
                  </button>
                <% end %>  
              </div>
              <div class="multi-item-carousel__prev-next">
                <button class="multi-item-carousel__arrow multi-item-carousel__arrow--prev" aria-label="Go to previous slide">
                  <svg role="img" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M12.9168 4.16663L7.0835 9.99996L12.9168 15.8333" stroke="black" stroke-width="1.5"/>
                  </svg>
                </button>
                <button class="multi-item-carousel__arrow multi-item-carousel__arrow--next" aria-label="Go to next slide">
                  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M7.0835 4.16663L12.9168 9.99996L7.0835 15.8333" stroke="black" stroke-width="1.5"/>
                  </svg>
                </button>
              </div>
            </div>
          </div>
          </div>

          <div class="d-none d-sm-block d-md-none">
            <div class="multi-item-carousel">
            <% items_per_slide = 2 %>
            <% total_slides = (@api_resources.count.to_f / items_per_slide).ceil %>
            <% item_index = 0 %>
            <div class="multi-item-carousel__slides opacity-0">
              
            <% total_slides.times do |i| %>
              <% items_added = 0 %>
              <div class="multi-item-carousel__slide d-flex" data-slide-index="<%= i %>">
                <% while item_index < @api_resources.count && items_added < items_per_slide %>
                  <% resource = @api_resources[item_index] %>
                  <% min_price = 1000000 %>
                  <% resource.properties['variants'].each do |variant| %>
                    <% if variant['price'] < min_price %>
                      <% min_price = variant['price'] %>
                    <% end %>
                  <% end %>
                  <% item_index += 1 %>
                  <% items_added += 1 %>
                  <a class="product__link-wrapper" href="/product-details?id=<%= resource.id %>">
                    <article class="product">
                      <img class="product__image" src="<%= resource.properties['default_image_url'] %>" alt="<%= resource.properties['title'] %>">
                      <p class="product__category">
                        <%= resource.properties['sub_categories'].empty? ? resource.properties['categories'][0] : resource.properties['sub_categories'][0] %>
                      </p>
                      <div class="product__info">
                        <h3 class="product__title">
                          <%= resource.properties['title'] %>
                        </h3>
                        <p class="product__price">
                          From
                          <data value="<%= min_price.to_f / 100 %>">
                            $<%= min_price.to_f / 100 %>  
                          </data>
                        </p>
                      </div>
                    </article>
                  </a> 
                <% end %>
              </div>
            <% end %>
            </div>
            <div class="multi-item-carousel__controls opacity-0">
              <div class="multi-item-carousel__indicators">
                <% total_slides.times do |i| %>
                  <button class="multi-item-carousel__indicator" aria-label="Go to slide <%= i + 1 %>" data-slide-index="<%= i %>">
                  </button>
                <% end %>  
              </div>
              <div class="multi-item-carousel__prev-next">
                <button class="multi-item-carousel__arrow multi-item-carousel__arrow--prev" aria-label="Go to previous slide">
                  <svg role="img" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M12.9168 4.16663L7.0835 9.99996L12.9168 15.8333" stroke="black" stroke-width="1.5"/>
                  </svg>
                </button>
                <button class="multi-item-carousel__arrow multi-item-carousel__arrow--next" aria-label="Go to next slide">
                  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M7.0835 4.16663L12.9168 9.99996L7.0835 15.8333" stroke="black" stroke-width="1.5"/>
                  </svg>
                </button>
              </div>
            </div>
          </div>
          </div>

          <div class="d-none d-md-block">
            <div class="multi-item-carousel">
            <% items_per_slide = 3 %>
            <% total_slides = (@api_resources.count.to_f / items_per_slide).ceil %>
            <% item_index = 0 %>
            <div class="multi-item-carousel__slides opacity-0">
              
            <% total_slides.times do |i| %>
              <% items_added = 0 %>
              <div class="multi-item-carousel__slide d-flex" data-slide-index="<%= i %>">
                <% while item_index < @api_resources.count && items_added < items_per_slide %>
                  <% resource = @api_resources[item_index] %>
                  <% min_price = 1000000 %>
                  <% resource.properties['variants'].each do |variant| %>
                    <% if variant['price'] < min_price %>
                      <% min_price = variant['price'] %>
                    <% end %>
                  <% end %>
                  <% item_index += 1 %>
                  <% items_added += 1 %>
                  <a class="product__link-wrapper" href="/product-details?id=<%= resource.id %>">
                    <article class="product">
                      <img class="product__image" src="<%= resource.properties['default_image_url'] %>" alt="<%= resource.properties['title'] %>">
                      <p class="product__category">
                        <%= resource.properties['sub_categories'].empty? ? resource.properties['categories'][0] : resource.properties['sub_categories'][0] %>
                      </p>
                      <div class="product__info">
                        <h3 class="product__title">
                          <%= resource.properties['title'] %>
                        </h3>
                        <p class="product__price">
                          From
                          <data value="<%= min_price.to_f / 100 %>">
                            $<%= min_price.to_f / 100 %>  
                          </data>
                        </p>
                      </div>
                    </article>
                  </a> 
                <% end %>
              </div>
            <% end %>
            </div>
            <div class="multi-item-carousel__controls opacity-0">
              <div class="multi-item-carousel__indicators">
                <% total_slides.times do |i| %>
                  <button class="multi-item-carousel__indicator" aria-label="Go to slide <%= i + 1 %>" data-slide-index="<%= i %>">
                  </button>
                <% end %>  
              </div>
              <div class="multi-item-carousel__prev-next">
                <button class="multi-item-carousel__arrow multi-item-carousel__arrow--prev" aria-label="Go to previous slide">
                  <svg role="img" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M12.9168 4.16663L7.0835 9.99996L12.9168 15.8333" stroke="black" stroke-width="1.5"/>
                  </svg>
                </button>
                <button class="multi-item-carousel__arrow multi-item-carousel__arrow--next" aria-label="Go to next slide">
                  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M7.0835 4.16663L12.9168 9.99996L7.0835 15.8333" stroke="black" stroke-width="1.5"/>
                  </svg>
                </button>
              </div>
            </div>
          </div>
          </div> 
          HTML
  )

site.snippets.create(
  label: "orders-best-selling-items-carousel", 
  identifier: "orders-best-selling-items-carousel",
  category_ids: [snippet_category.id],
  content:  <<~HTML
            <% received_orders = @api_resources.where.not("properties->>'printify_status'IN(?)", ['canceled', 'initialized']) %>
            <% products_sold_count_map = received_orders.group("jsonb_array_elements(properties->'line_items')->>'product_id'").count %>
            <% best_selling_products_ids = Hash[products_sold_count_map.sort_by {|key, value| value}.reverse].keys.first(5) %>
            <% best_selling_products = ApiNamespace.friendly.find('products').api_resources.jsonb_search(:properties, {printify_product_id: {value: best_selling_products_ids, option: 'PARTIAL', match: 'ANY'}}).first(5) %>
              <div class="single-item-carousel">
                <button class="single-item-carousel__arrow single-item-carousel__arrow--prev opacity-0">
                  {{ cms:snippet carousel-control-prev-icon }}
                </button>
                <div class="single-item-carousel__middle-container opacity-0">
                  <div class="single-item-carousel__slides">
                    <% best_selling_products.each_with_index do |resource, i| %>
                      <div class="single-item-carousel__slide" data-slide-index="<%= i %>">
                        <a href="/product-details?id=<%= resource.id %>">
                          <img class="product__image" src="<%= resource.properties['default_image_url'] %>" alt="<%= resource.properties['default_image_url'] %>">
                        </a>
                      </div>
                    <% end %>
                  </div>
                  <div class="single-item-carousel__indicators">
                    <% best_selling_products.each_with_index do |resource, i| %>
                      <button class="single-item-carousel__indicator" aria-label="Go to slide <%= i + 1 %>" data-slide-index="<%= i %>"></button>
                    <% end %>
                  </div>
                </div>
                <button class="single-item-carousel__arrow single-item-carousel__arrow--next opacity-0">
                  {{ cms:snippet carousel-control-next-icon }}
                </button>
              </div>
              <div class="best-selling-items__info-container">
                <% best_selling_products.each_with_index do |resource, i| %>
                  <% min_price = 1000000 %>
                  <% resource.properties['variants'].each do |variant| %>
                    <% if variant['price'] < min_price %>
                      <% min_price = variant['price'] %>
                    <% end %>
                  <% end %>
                  <div class="best-selling-items__info <%= i != 0 ? 'd-none' : '' %>" data-slide-index="<%= i %>">
                    <a class="product__link-wrapper" href="/product-details?id=<%= resource.id %>">
                      <p class="product__category">
                        <%= resource.properties['sub_categories'].empty? ? resource.properties['categories'][0] : resource.properties['sub_categories'][0] %>
                      </p>
                      <h3 class="best-selling-items__product-title">
                        <%= resource.properties['title'] %>
                      </h3>
                      <p class="product__price">
                        From
                        <data value="<%= min_price.to_f / 100 %>">
                            $<%= min_price.to_f / 100 %>  
                        </data>
                      </p>
                    </a>
                  </div>
                <% end %>
              </div>
              HTML
)

p "###################################                      CREATING SCRIPTS                     ###################################"

site.snippets.create(
  label: 'custom-shop-script', 
  identifier: 'custom-shop-script',
  category_ids: [snippet_category.id, script_category.id],
  content: <<~JAVASCRIPT
            function init() {
              const multiItemCarousels = document.querySelectorAll(".multi-item-carousel");
              multiItemCarousels.forEach(carousel => {
                const carouselConfig = {
                  carouselType: "multi-item-carousel",
                  parentContainer: carousel.parentElement
                };
                initCarousel(carouselConfig);
                initBestSellingItemsCarousel();
              });
            }
            
            init();
            JAVASCRIPT
           
)

site.snippets.create(
  label: 'product-details-script', 
  identifier: 'product-details-script',
  category_ids: [snippet_category.id, script_category.id],
  content:  <<~JAVASCRIPT
            async function init() {
              const optionsForm = document.querySelector(".options-form");
              const buyNowButton = optionsForm.querySelector(".btn--buy-now");
            
              const product = await getProductAsync(getProductInfo().id);
              const shopId = product.properties.printify_shop_id;
              const variants = product.properties["variants"].filter(variant => variant.is_enabled);
              const images = product.properties["images"];
            
              const carouselConfig = {
                carouselType: "single-item-carousel",
                callback: showVariantImageInCarousel,
                callbackArgs: [getSelectedVariant(variants)]
              };
              
              initCarousel(carouselConfig);
              
              optionsForm.addEventListener("submit", function(e) {
                e.preventDefault();
                const selectedVariant = getSelectedVariant(variants);
                addProductToBrowserStorage(selectedVariant, images, shopId);
                setItemCountInCartIcon();
                initToast(document.querySelector(".toast-container"), "Item added to cart");
              });
            
              buyNowButton.addEventListener("click", function() {
                const selectedVariant = getSelectedVariant(variants);
                addProductToBrowserStorage(selectedVariant, images, shopId);
                window.location.href = `${window.location.origin}/cart`;
              });
            
              $('.options-container:first .option > input[type="radio"]').on('input', function() {
                if ($(this).is(':checked')) {
                  let availableOptions = $(this).parent().data('availableOptions');
                  $('.options-container:not(:first-child)').each(function() {
                    let options = $(this).find('input[type="radio"]');
                    options.each(function () {
                      if (availableOptions.includes($(this).data('optionId'))) {
                        $(this).parent().show();
                      } else {
                        $(this).parent().hide();
                        if ($(this).is(':checked')) {
                          options.filter(function() { return availableOptions.includes($(this).data('optionId'))}).first().prop("checked", true);
                        }
                      }
                    })
                  })
                }
              }).trigger("input")
            
              // Update variant information when selected options change
              optionsForm.addEventListener("input", function(e) {
                updateVariantInfo(variants);
              });
            }
            
            function updateVariantInfo(variants) {
              const selectedVariant = getSelectedVariant(variants);
              const variantTitle = document.querySelector(".product__variant-title");
              const variantPrice = document.querySelector(".product__variant-price");
              const variantAvailability = document.querySelector(".product__variant-availability");
              const buyNowButton = document.querySelector(".btn--buy-now");
              const addToCartButton = document.querySelector(".btn--add-to-cart");
            
              variantTitle.textContent = selectedVariant['title'];
              variantPrice.textContent = `\$${selectedVariant['price'] / 100}`;
              
              if (selectedVariant['is_available']) {
                variantAvailability.textContent = "In stock";
                buyNowButton.removeAttribute("disabled");
                addToCartButton.removeAttribute("disabled");
              } else {
                variantAvailability.textContent = "Not in stock";
                buyNowButton.setAttribute("disabled", "");
                addToCartButton.setAttribute("disabled", "");
              }
              showVariantImageInCarousel(selectedVariant);
            }
            
            function showVariantImageInCarousel(variant) {
              const carousel = document.querySelector(".single-item-carousel");
              const slides = [...carousel.querySelectorAll(".single-item-carousel__slide")];
              const variantChangeEventName = getConfig()["CUSTOM_EVENTS"]["VARIANT_CHANGE"];
              const newSlide = getVariantImageSlide(variant.id, slides);
              
              // Dispatch variant change event to the carousel so that it can change the current slide
              const variantChangeEvent = new CustomEvent(variantChangeEventName, { detail: newSlide.dataset.slideIndex });
              carousel.dispatchEvent(variantChangeEvent);
            }
            
            // Looks for the first front-facing variant image
            // Otherwise, it gets any other variant image, or the default image in case there is no dedicated variant image
            function getVariantImageSlide(variantId, slides) {
              let frontImageSlide;
              let anyOtherImageSlide;
              let defaultImageSlide;
            
              for (let i = 0; i < slides.length; i++) {
                const slide = slides[i];
                const variantIds = JSON.parse(slide.dataset.variantIds);                           
                const imagePosition = slide.dataset.imagePosition;
                
                if (variantIds.includes(variantId) && imagePosition === "front") return slide;
            
                if (!anyOtherImageSlide && variantIds.includes(variantId)) {
                  anyOtherImageSlide = slide;
                }
            
                if (!defaultImageSlide && slide.dataset.isDefaultImage === "true") {
                  defaultImageSlide = slide;
                }
              }
              return anyOtherImageSlide ?? defaultImageSlide;
            }
            
            function getProductInfo() {
              return {
                id: document.querySelector(".product").dataset.productId,
                title: document.querySelector(".product__title").textContent
              };
            }
            
            // Get variant based on selected options - find using selected option IDs and variant Option IDs
            function getSelectedVariant(variants) {
              const selectedOptionIds = Array.from(document.querySelectorAll(".options-form input:checked")).map(option => Number.parseFloat(option.dataset.optionId));
              return variants.find(variant => variant['options'].every(id => selectedOptionIds.includes(id)));
            }
            
            // Add selected item to cart in browser storage
            function addProductToBrowserStorage(selectedVariant, images, shopId) {
              const cart = getCart();
            
              // If the selected variant already exists in the cart, then its quantity needs to be incremented, otherwise add the product with quantity: 1
              const item = cart.line_items.find(variant => variant.variant_id === selectedVariant.id);
              if (item) {
                const updatedCart = {
                  ...cart,
                  line_items: [
                    ...cart.line_items.filter(variant => variant.variant_id !== selectedVariant.id),
                    {...item, quantity: item.quantity + 1}
                  ]
                };
                setCart(updatedCart);
                return;
              }
              const productInfo = getProductInfo();
              const variantImage = getVariantImage(selectedVariant.id, images);
              const updatedCart = {
                ...cart,
                line_items: [
                  ...cart.line_items,
                  {
                    product_id: productInfo.id,
                    shop_id: shopId,
                    product_title: productInfo.title,
                    variant_id: selectedVariant.id,
                    variant_title: selectedVariant.title,
                    price: selectedVariant.price,
                    quantity: 1,
                    images: [variantImage.src]
                  }
                ]
              };
              setCart(updatedCart);
            }
            
            init();
            JAVASCRIPT
)


site.snippets.create(
  label: 'cart-script', 
  identifier: 'cart-script',
  category_ids: [snippet_category.id, script_category.id],
  content: <<~JAVASCRIPT
            async function init() {
              const cart = getCart();
              let products = [];
            
              let shopDetails = getShopDetails()[0];
              if (!shopDetails) {
                shopDetails = await getShopDetailsAsync()[0];
              }
            
              const cartItemsContainer = document.querySelector(".cart-items");
              const checkoutButton = document.querySelector(".btn--checkout");
              const shippingCountryDropdown = document.querySelector(".shipping-country select");
              const handleQuantityChangeDebounced = debounce(handleQuantityChange, 400);
              let priceDetails = {};
            
              setItemsCountText(cart.line_items.length);
            
              // Render options for shipping countries dropdown
              shopDetails.shipping_countries.forEach(country => {
                // No need to add Canada and United States since they have already been added as the top two options in the HTML
                if (country.country_code === "CA" || country.country_code === "US") return;
                const markup = `<option value="${country.country_code}">${country.country_name}</option>`;
                shippingCountryDropdown.insertAdjacentHTML("beforeEnd", markup);
              });
            
              if (cart.line_items.length > 0) {
                const productIds = cart.line_items.map(variant => variant.product_id);
                products = await getProductsAsync(productIds);
            
                // Render cart items
            
                insertCartItems(cart);
                const cartItems = document.querySelectorAll(".cart-item");
                // Render options dropdowns for each cart item
            
                cartItems.forEach((cartItem) => {
                  const productId = cartItem.dataset.productId;
                  const product = products.find(
                    (product) => product.properties.printify_product_id === productId
                  );
                  const cartOptionsContainer = cartItem.querySelector(
                    ".cart-item__options"
                  );
                  insertOptionsSelectElements(product, cartOptionsContainer);
            
                  const firstOptionsSelectElement = cartOptionsContainer.querySelector(".cart-item__option:first-child select");
                  
                  showAvailableOptions(firstOptionsSelectElement);
                });
            
                // Add event listeners for removing or modifying cart items
            
                cartItemsContainer.addEventListener("click", handleClickRemoveCartItem);
                cartItemsContainer.addEventListener("change", function (e) {
                  if (e.target.closest(".cart-item__options")) {
                    handleOptionChange(e);
                  }
                });
                cartItemsContainer.addEventListener("input", function (e) {
                  if (e.target.closest(".cart-item__quantity")) {
                    handleQuantityChangeDebounced(e);
                  }
                });
              } else {
                insertContentForEmptyCart();
              }
            
              checkoutButton.addEventListener("click", function (e) {
                handleClickCheckout(e, priceDetails);
              });
            
              shippingCountryDropdown.addEventListener("change", setPricesAsync);
            
              setPricesAsync();
            
              async function handleClickCheckout(e, priceDetails) {
                const noPriceDetails = Object.keys(priceDetails).length === 0;
                if (noPriceDetails) return;
            
                const cart = getCart();
                if (cart.line_items.length === 0) return;
            
                const checkoutButton = e.target;
                const shippingCountry = document.querySelector(".shipping-country select").value;
                const errorMessageElement = document.querySelector(".order-summary__price-details .error-message");
            
                const url = getConfig()["CHECKOUT_URL"];
                const payload = {
                  data: {
                    line_items: cart.line_items.map(item => ({
                      product_id: item.product_id,
                      variant_id: item.variant_id,
                      quantity: item.quantity,
                      images: item.images
                    })),
                    shipping_and_processing_charges: {
                      shipping_charge: priceDetails.shipping_charge,
                      stripe_processing_fee: priceDetails.stripe_processing_fee
                    },
                    shop_id: shopDetails.shop_id,
                    country_code: shippingCountry
                  }
                };
            
                // Show loading state
                checkoutButton.setAttribute("disabled", "");
                checkoutButton.textContent = "Processing...";
            
                if (errorMessageElement) errorMessageElement.remove();
            
                try {
                  const response = await fetch(url, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(payload)
                  });
            
                  if (!response.ok) {
                    throw new Error(getConfig()["ERROR_MESSAGES"]["CHECKOUT"]);
                  }
                  const { data } = await response.json();
                  window.location.href = data.checkout_url;
                } catch (error) {
                    const errorMessageMarkup = `<p class="error-message">
                        ${error.message}      
                      </p>
                    `;
                    document.querySelector(".order-summary__price-details").insertAdjacentHTML("beforeEnd", errorMessageMarkup);
                } finally {
                  // Hide loading state
                  checkoutButton.removeAttribute("disabled");
                  checkoutButton.textContent = "Checkout";
                }
              }
            
              function insertContentForEmptyCart() {
                const emptyCartText = document.querySelector(
                  ".cart-items .empty-cart-text"
                );
                if (emptyCartText) return;
                const cartItemsContainer = document.querySelector(".cart-items");
                const markup = `
                <p class="empty-cart-text">Your cart is empty</p>
                <a class="btn btn-primary" href="/custom-shop">Return to shop</a>
              `;
                cartItemsContainer.insertAdjacentHTML("beforeEnd", markup);
              }
            
              function setItemsCountText(itemsCount) {
                const cartItemsTitleItemCountElement = document.querySelector(
                  ".cart-items-section .section-title__item-count"
                );
                const orderSummaryTitleItemCountElement = document.querySelector(
                  ".order-summary .section-title__item-count"
                );
                const itemsText = `${itemsCount} ${itemsCount === 1 ? "item" : "items"}`;
            
                cartItemsTitleItemCountElement.textContent = `(${itemsText})`;
                orderSummaryTitleItemCountElement.textContent = `(${itemsText})`;
              }
            
              function handleQuantityChange(e) {
                if (e.target.value === "") return;
                if (Number.parseFloat(e.target.value) <= 0) {
                  e.target.value = 1;
                }
                                                          
                const newQuantity = Number.parseFloat(e.target.value);
                const cartItem = e.target.closest(".cart-item");
                const variantId = Number.parseFloat(cartItem.dataset.variantId);
                const cart = getCart();
                const item = cart.line_items.find((item) => item.variant_id === variantId);
                const priceElement = cartItem.querySelector(".cart-item__price data");
                const formattedPrice = getFormattedPrice(item.price * newQuantity);
            
                // Update variant price in the DOM based on the new quantity
            
                priceElement.value = formattedPrice.value;
                priceElement.textContent = formattedPrice.text;
            
                // Update variant in browser storage
            
                const itemWithUpdatedQuantity = {
                  ...item,
                  quantity: newQuantity,
                };
                const updatedCart = {
                  ...cart,
                  line_items: [
                    ...cart.line_items.filter((item) => item.variant_id !== variantId),
                    itemWithUpdatedQuantity,
                  ],
                };
            
                setCart(updatedCart);
            
                // Set updated price details
                setPricesAsync();
              }
            
              // Creates a select element for each option type of a product
              function insertOptionsSelectElements(product, parentContainer) {
                // Only insert select elements if there aren't any
                if (parentContainer.children.length > 0) return;
                  
                const enabledVariants = product.properties.variants.filter(variant => variant.is_enabled);
                const enabledOptionIds = new Set(enabledVariants.flatMap(variant => variant.options));
                const variantId = Number.parseFloat(
                  parentContainer.closest(".cart-item").dataset.variantId
                );
                const variant = product.properties.variants.find(
                  (variant) => variant.id === variantId
                );
                product.properties.options.forEach((option) => {
                  const selectContainer = document.createElement("div");
                  selectContainer.className = "cart-item__option cart-form-control";
                  const optionName = option.name.toLowerCase();
            
                  const labelElement = document.createElement("label");
                  labelElement.textContent = `${option.name}:`;
                  labelElement.setAttribute("for", optionName);
            
                  const selectElement = document.createElement("select");
                  selectElement.name = optionName;
                  selectElement.id = optionName;
            
                  selectContainer.appendChild(labelElement);
                  selectContainer.appendChild(selectElement);
                  
                  const availableOptionValues = option.values.filter(value => enabledOptionIds.has(value.id));
            
                  availableOptionValues.forEach((value) => {
                    const selectOptionMarkup = `
                      <option value="${value.id}" data-available-options="${JSON.stringify(value.available_options)}">${value.title}</option>
                    `;
                    selectElement.insertAdjacentHTML("beforeEnd", selectOptionMarkup);
            
                    // If value id matches with one of the option IDs of the variant, then that should be the initial value of the select element
                    if (variant.options.includes(value.id)) selectElement.value = value.id;
                  });
            
                  parentContainer.appendChild(selectContainer);
                });
              }
                  
              // the selected option in the reference options dropdown must be present as a companion option of all available options for each of the other option types
              function showAvailableOptions(referenceOptionsSelectElement) {
                  const cartItem = referenceOptionsSelectElement.closest(".cart-item");
                  const referenceOptionId = Number.parseFloat(referenceOptionsSelectElement.value);
                  const otherOptionsSelectElements = cartItem.querySelectorAll(`select:not([name="${referenceOptionsSelectElement.name}"]`);
                otherOptionsSelectElements.forEach(selectElement => {
                  const optionElements = selectElement.querySelectorAll("option");
                  optionElements.forEach(optionElement => {
                    const availableOptions = JSON.parse(optionElement.dataset.availableOptions);
                    if (availableOptions.includes(referenceOptionId)) {
                      optionElement.classList.remove("d-none");
                    } else {
                      optionElement.classList.add("d-none");
                    }
                    // If the selected option is no longer an available option, then select the first available option
                    const selectedOption = selectElement.querySelector(`option[value="${selectElement.value}"]`);
                    if (selectedOption.classList.contains("d-none")) {
                      const firstAvailableOption = selectElement.querySelector("option:not(.d-none)");
                      selectElement.value = firstAvailableOption.value;
                    }
                  });
                }); 
              }
            
              function handleOptionChange(e) {
                const cart = getCart();
                const cartItem = e.target.closest(".cart-item");
                const oldVariantId = Number.parseFloat(cartItem.dataset.variantId);
                const productId = cartItem.dataset.productId;
                  
                const firstOptionsSelectElement = cartItem.querySelector(".cart-item__option:first-of-type select");
                  
                const selectElements = cartItem.querySelectorAll(".cart-item__option select");
                        
                // Update other options dropdowns to show only available options
                showAvailableOptions(firstOptionsSelectElement);
            
                const selectedOptionIds = [...selectElements].map((elem) =>
                  Number.parseFloat(elem.value)
                );
            
                // get the new variant
            
                const product = products.find(
                  (product) => product.properties.printify_product_id === productId
                );
                const newVariant = getVariantFromOptionIds(product, selectedOptionIds);
                const variantImage = getVariantImage(
                  newVariant.id,
                  product.properties["images"]
                );
            
                // update variant info in the DOM
            
                const variantTitleElement = cartItem.querySelector(
                  ".cart-item__variant-title"
                );
                const variantPriceElement = cartItem.querySelector(
                  ".cart-item__price data"
                );
                const variantImageElement = cartItem.querySelector(
                  ".cart-item__image-container img"
                );
                const formattedPrice = getFormattedPrice(newVariant.price);
            
                cartItem.setAttribute("data-variant-id", newVariant.id);
                variantTitleElement.textContent = newVariant.title;
                variantImageElement.src = variantImage.src;
                variantPriceElement.value = formattedPrice.value;
                variantPriceElement.textContent = formattedPrice.text;
                  
                // Quantity should be reset to 1 when variant changes
                cartItem.querySelector(".cart-item__quantity input").value = 1;
                  
                // update cart (delete old variant and add new variant)
            
                const newItem = {
                  product_id: productId,
                  variant_id: newVariant.id,
                  shop_id: shopDetails.shop_id,
                  product_title: product.properties.title,
                  variant_title: newVariant.title,
                  price: newVariant.price,
                  quantity: 1,
                  images: [variantImage.src],
                };
            
                const updatedCart = {
                  ...cart,
                  line_items: [
                    ...cart.line_items.filter((item) => item.variant_id !== oldVariantId),
                    newItem,
                  ],
                };
            
                setCart(updatedCart);
            
                // set updated price details
                setPricesAsync();
              }
            
              function insertCartItems(cart) {
                const cartItemsContainer = document.querySelector(".cart-items");
                // Only insert cart items if there are no cart items (prevent duplicate cart items upon Turbo navigation)
                if (cartItemsContainer.children.length > 0) return;
                let itemsMarkup = "";
                cart.line_items.forEach((variant) => {
                  const formattedPrice = getFormattedPrice(
                    variant.price * variant.quantity
                  );
                  itemsMarkup += `
                  <article class="cart-item" data-variant-id="${variant.variant_id}" data-product-id="${variant.product_id}">
                    <div class="cart-item__image-container">
                      <img src="${variant.images[0]}" alt="${variant.variant_title} ${variant.product_title}">
                    </div>
                    <div class="cart-item__text-content">
                      <div class="cart-item__heading">
                        <hgroup>
                          <p class="cart-item__variant-title">
                            ${variant.variant_title}
                          </p>
                          <h3 class="cart-item__product-title">
                            ${variant.product_title}
                          </h3>
                        </hgroup>
                        <button type="button" class="btn--remove" aria-label="Remove item from cart">
                          {{ cms:snippet trash-icon }}
                        </button>
                      </div>
                      <div class="cart-item__form-controls">
                        <div class="cart-item__options">
                      
                        </div>
                        <div class="cart-item__quantity cart-form-control">
                          <label for="quantity">Quantity:</label>
                          <input type="number" name="quantity" id="quantity" min="1" value="${variant.quantity}">
                        </div>
                      </div>
                      <p class="cart-item__price">
                        Price: <data value="${formattedPrice.value}">${formattedPrice.text}</data>
                      </p>
                    </div> 
                  </article>
                `;
                });
                cartItemsContainer.insertAdjacentHTML("beforeEnd", itemsMarkup);
              }
            
              function handleClickRemoveCartItem(e) {
                const removeButton = e.target.closest(".btn--remove");
                if (!removeButton) return;
            
                const parentContainer = removeButton.closest(".cart-item");
                const variantId = Number.parseFloat(parentContainer.dataset.variantId);
                const quantity = Number.parseFloat(parentContainer.querySelector(".cart-item__quantity input").value);
                const cart = getCart();
                  
                let itemRemoved = false;
            
                // Remove item from browser storage
                // Only one item should be removed even if there are multiple items with the same variant ID and quantity
                // There could be multiple items with the same variant ID if the user adds variants of the same product to the cart and then changes the variants on the cart page
                const updatedCart = {
                  ...cart,
                  line_items: cart.line_items.filter(
                    (item) => {
                      if (!itemRemoved && (item.variant_id === variantId && quantity === item.quantity)) {
                        itemRemoved = true;
                        return false;
                      }
                      return itemRemoved || item.variant_id !== variantId;
                    }
                  ),
                };
                setCart(updatedCart);
            
                // Remove item from the DOM
                parentContainer.remove();
            
                // Insert content for empty cart and hide checkout button
                if (updatedCart.line_items.length === 0) {
                  insertContentForEmptyCart();
                  hideElement(".btn--checkout");
                }
            
                // Update items count in section titles
                setItemsCountText(updatedCart.line_items.length);
            
                // Update items count in cart icon
                setItemCountInCartIcon();
                  
              // Show toast
              initToast(document.querySelector(".toast-container"), "Item removed from cart");
            
                // Update price details
                setPricesAsync();
              }
            
              function setPrice(selector, price) {
                const priceElement = document.querySelector(`${selector} data`);
                const formattedPrice = getFormattedPrice(price);
            
                priceElement.textContent = formattedPrice.text;
                priceElement.value = formattedPrice.value;
              }
            
              // fetch total price, subtotal price, shipping and processing fees
              async function getPriceDetails(cart) {
                const config = getConfig();
                const url = config["PRICE_DETAILS_URL"];
                const shippingCountry = document.querySelector(".shipping-country select").value;
                const payload = {
                  data: {
                    shop_id: shopDetails.shop_id,
                    line_items: cart.line_items.map((item) => ({
                      product_id: item.product_id,
                      variant_id: item.variant_id,
                      quantity: item.quantity,
                    })),
                    address_to: { country: shippingCountry },
                  },
                };
                try {
                  const response = await fetch(url, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(payload),
                  });
              
                  if (!response.ok) {
                    throw new Error(getConfig()["ERROR_MESSAGES"]["PRICE_DETAILS"]);
                  }
                  const { data } = await response.json();
                  return data;
                } catch (error) {
                  throw(error);
                }
              }
            
              async function setPricesAsync() {
                const cart = getCart();
                const errorMessageElement = document.querySelector(
                  ".order-summary__price-details .error-message"
                );
            
                if (cart.line_items.length === 0) {
                  setPrice(".price-detail--subtotal", 0);
                  setPrice(".price-detail--convenience", 0);
                  setPrice(".price-detail--shipping", 0);
                  setPrice(".price-detail--total", 0);
                  return;
                }
            
                // show loading state
                showElement(".order-summary__loading");
                hideElement(".order-summary__fees");
                hideElement(".btn--checkout");
            
                if (errorMessageElement) errorMessageElement.remove();
            
                try {
                  // Need to get the most up-to-date shop details in case they change from the backend
                  // This ensures that shop details both on the frontend and backend are in sync
                  const shopDetails = await getShopDetailsAsync();
                  
                  
                  // Save shop details to browser storage in case there are any changes
                  sessionStorage.setItem(getConfig()["SHOP_DETAILS_KEY"], JSON.stringify(shopDetails));
                  
                  const shouldCollectTax = shopDetails[0].collect_sales_tax;
                  const shouldChargeProcessingFee = shopDetails[0].pass_processing_fees_to_customer;
            
                  if (shouldCollectTax) {
                    document.querySelector(".tax-exclusive-text").classList.remove("d-none");
                  }
            
                  if (shouldChargeProcessingFee) {
                    document.querySelector(".price-detail--convenience").classList.remove("d-none");
                  }
            
                  priceDetails = await getPriceDetails(cart);
            
                  setPrice(".price-detail--subtotal", priceDetails.cart_total_items_cost);
                  shouldChargeProcessingFee && setPrice(".price-detail--convenience", priceDetails.stripe_processing_fee);
                  setPrice(".price-detail--shipping", priceDetails.shipping_charge);
                  setPrice(".price-detail--total", priceDetails.total_amount_to_charge_customer);
            
                  // hide loading state once fees have been calculated
                  hideElement(".order-summary__loading");
                  showElement(".order-summary__fees");
                  if (cart.line_items.length > 0) showElement(".btn--checkout");
                } catch (error) {
                  const errorMessageMarkup = `<p class="error-message">
                    ${error.message}      
                  </p>`;
            
                  hideElement(".order-summary__loading");
                  showElement(".order-summary__fees");
            
                  document.querySelector(".order-summary__price-details").insertAdjacentHTML("beforeEnd", errorMessageMarkup);
                }
              }
            
              function getVariantFromOptionIds(product, optionIds) {
                const enabledVariants = product.properties.variants.filter(variant => variant.is_enabled);
                return enabledVariants.find((variant) =>
                  variant.options.every((option) => optionIds.includes(option))
                );
              }
            }
            
            init(); 
            JAVASCRIPT
)

site.snippets.create(
  label: 'checkout-success-script', 
  identifier: 'checkout-success-script',
  category_ids: [snippet_category.id, script_category.id],
  content:  <<~JAVASCRIPT
            function emptyCart() {
              const cart = getCart();
              const updatedCart = {
                ...cart,
                line_items: [],
              }
              setCart(updatedCart);
              setItemCountInCartIcon();
            }
            emptyCart();
            JAVASCRIPT
)

p "###################################                       CREATING ICONS                      ###################################"

site.snippets.create(
  label: 'cart-icon', 
  identifier: 'cart-icon',
  category_ids: [snippet_category.id, icon_snippet_category.id],
  content:  <<~HTML
            <svg role="img" width="20" height="23" viewBox="0 0 20 23" fill="none" xmlns="http://www.w3.org/2000/svg">
            <title>View cart</title>
            <path d="M12.9924 17.4487C11.6582 17.4487 10.5635 18.6081 10.5635 20.0135C10.5635 21.4189 11.6582 22.5784 12.9924 22.5784C14.3266 22.5784 15.4214 21.4189 15.4214 20.0135C15.4556 18.6081 14.3608 17.4487 12.9924 17.4487ZM12.9924 21.3487C12.3082 21.3487 11.7608 20.7514 11.7608 20.0135C11.7608 19.2757 12.3082 18.6784 12.9924 18.6784C13.6766 18.6784 14.224 19.2757 14.224 20.0135C14.2582 20.7514 13.6766 21.3487 12.9924 21.3487Z" fill="#212B36"/>
            <path d="M5.2268 17.4487C3.89259 17.4487 2.79785 18.6081 2.79785 20.0135C2.79785 21.4189 3.89259 22.5784 5.2268 22.5784C6.56101 22.5784 7.65574 21.4189 7.65574 20.0135C7.68995 18.6081 6.59522 17.4487 5.2268 17.4487ZM5.2268 21.3487C4.54259 21.3487 3.99522 20.7514 3.99522 20.0135C3.99522 19.2757 4.54259 18.6784 5.2268 18.6784C5.91101 18.6784 6.45837 19.2757 6.45837 20.0135C6.49258 20.7514 5.91101 21.3487 5.2268 21.3487Z" fill="#212B36"/>
            <path d="M18.7741 0.970276H16.5846C16.0714 0.970276 15.6267 1.35676 15.5583 1.88379L14.9425 6.52163H1.49776C1.18986 6.52163 0.916176 6.66217 0.745123 6.90811C0.574071 7.15406 0.50565 7.47028 0.574071 7.75136V7.78649L2.66091 14.427C2.76354 14.8487 3.13986 15.1649 3.61881 15.1649H13.7109C14.4635 15.1649 15.0793 14.6027 15.182 13.8297L16.7557 2.16487H18.8083C19.1504 2.16487 19.4241 1.88379 19.4241 1.53244C19.4241 1.18109 19.1162 0.970276 18.7741 0.970276ZM13.9504 13.6541C13.9162 13.7946 13.8135 13.9351 13.6425 13.9351H3.72144L1.77144 7.75136H14.7372L13.9504 13.6541Z" fill="#212B36"/>
            </svg>
            HTML
)

site.snippets.create(
  label: 'trash-icon', 
  identifier: 'trash-icon',
  category_ids: [snippet_category.id, icon_snippet_category.id],
  content:  <<~HTML
            <svg role="img" width="13" height="15" viewBox="0 0 13 15" fill="none" xmlns="http://www.w3.org/2000/svg">
            <title>Remove item</title>
            <path d="M3.75 4.65625H4.6875V12.1562H3.75V4.65625Z" fill="#f7193e"/>
            <path d="M5.625 4.65625H6.5625V12.1562H5.625V4.65625Z" fill="#f7193e"/>
            <path d="M7.5 4.65625H8.4375V12.1562H7.5V4.65625Z" fill="#f7193e"/>
            <path d="M0 1.84375H12.1875V2.78125H0V1.84375Z" fill="#f7193e"/>
            <path d="M8.40625 2.3125H7.53125V1.375C7.53125 1.09375 7.3125 0.875001 7.03125 0.875001H5.15625C4.875 0.875001 4.65625 1.09375 4.65625 1.375V2.3125H3.78125V1.375C3.78125 0.624998 4.40625 0 5.15625 0H7.03125C7.78125 0 8.40625 0.624998 8.40625 1.375V2.3125Z" fill="#f7193e"/>
            <path d="M8.90625 14.9687H3.28125C2.53125 14.9687 1.875 14.3437 1.8125 13.5937L0.9375 2.34375L1.875 2.28125L2.75 13.5312C2.78125 13.8125 3.03125 14.0312 3.28125 14.0312H8.90625C9.1875 14.0312 9.4375 13.7813 9.4375 13.5312L10.3125 2.28125L11.25 2.34375L10.375 13.5937C10.3125 14.375 9.65625 14.9687 8.90625 14.9687Z" fill="#f7193e"/>
            </svg>
            HTML
)

site.snippets.create(
  label: 'check-icon', 
  identifier: 'check-icon',
  category_ids: [snippet_category.id, icon_snippet_category.id],
  content:  <<~HTML
            <svg aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
            <path fill-rule="evenodd" d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12zm13.36-1.814a.75.75 0 10-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 00-1.06 1.06l2.25 2.25a.75.75 0 001.14-.094l3.75-5.25z" clip-rule="evenodd" />
            </svg>
            HTML
)

site.snippets.create(
  label: 'carousel-control-next-icon', 
  identifier: 'carousel-control-next-icon',
  category_ids: [snippet_category.id, icon_snippet_category.id],
  content:  <<~HTML
            <svg role="img" width="10" height="13" viewBox="0 0 10 13" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M1.71656 12.2472L1.81534 12.1815L9.17701 7.21159C9.42632 7.04349 9.58155 6.79135 9.58155 6.50996C9.58155 6.22858 9.42162 5.97643 9.17701 5.80834L1.82946 0.842124L1.70715 0.758075C1.58955 0.695952 1.44844 0.659409 1.29791 0.659409C0.888668 0.659409 0.554688 0.929828 0.554688 1.26602V11.7466C0.554688 12.0828 0.888668 12.3532 1.29791 12.3532C1.45314 12.3532 1.59896 12.313 1.71656 12.2472Z" fill="black"/>
            </svg>
            HTML
)

site.snippets.create(
  label: 'carousel-control-prev-icon', 
  identifier: 'carousel-control-prev-icon',
  category_ids: [snippet_category.id, icon_snippet_category.id],
  content:  <<~HTML
            <svg role="img" width="10" height="13" viewBox="0 0 10 13" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M8.39575 0.76538L8.29696 0.831159L0.935293 5.80102C0.685984 5.96912 0.530754 6.22127 0.530754 6.50265C0.530754 6.78403 0.690688 7.03618 0.935293 7.20428L8.28285 12.1705L8.40515 12.2545C8.52275 12.3167 8.66387 12.3532 8.81439 12.3532C9.22364 12.3532 9.55762 12.0828 9.55762 11.7466L9.55762 1.26602C9.55762 0.929825 9.22364 0.659406 8.8144 0.659406C8.65917 0.659406 8.51334 0.699603 8.39575 0.76538Z" fill="black"/>
            </svg>
            HTML
)

products_page = layout.pages.create!(
  site_id: site.id,
  label: PRODUCTS_PAGE_SLUG,
  slug: PRODUCTS_PAGE_SLUG,
  category_ids: [page_category.id]
)

Comfy::Cms::Fragment.create!(
  identifier: 'content',
  record: products_page,
  tag: 'wysiwyg',
  content:  <<~HTML
            <style>
            .products {
              display: grid;
              grid-template-columns: 1fr;
              gap: 40px;
            }
            .product__image {
              margin-bottom: 24px;
            }
            .product__info {
              display: flex;
              justify-content: space-between;
            }
            .product__title {
              margin-bottom: 0;
              margin-right: 10px;
              font-size: 20px;
            }
            /* Media queries */
            @media only screen and (min-width: 576px) {
              .products {
                grid-template-columns: repeat(auto-fit, minmax(200px, var(--max-product-image-width)));
              }
            }
            </style><main><section class="section best-selling-items">
            <div class="restrictive-container">
              <p class="best-selling-items__section-subtitle">Most Popular Products
              </p>
              <h2 class="best-selling-items__section-title">Best Selling Items</h2>
              <div class="best-selling-items__carousel-container">
                {{ cms:helper render_api_namespace_resource_index 'orders', { snippet: 'orders-best-selling-items-carousel' } }}
              </div>
            </div>
            </section><section class="section">
            <div class="restrictive-container">
              <h2 class="section__title">Recently Added</h2>
              <p class="section__subtitle">These are the 10 latest available products shown in a carousel.
              </p>
              <div class="carousel-container">
                {{ cms:helper render_api_namespace_resource_index 'products', { snippet: 'products-multi-item-carousel', scope: { properties: { visible: true } }, order: { created_at: 'DESC' }, limit: 10 } }}
              </div>
            </div></section><section class="section">
            <div class="restrictive-container">
              <h2 class="section__title">All Products</h2>
              <p class="section__subtitle">These are all the available products shown in a grid view.
              </p>
              <div class="products">
                {{ cms:helper render_api_namespace_resource_index 'products', scope: { properties: { visible: true } }, order: { created_at: 'DESC' } }}
              </div>
            </div>
            </section></main>
            <script>{{ cms:snippet custom-shop-script }}
            </script>
            HTML
)


product_details_page = layout.pages.create!(
  site_id: site.id,
  label: 'product-details',
  category_ids: [page_category.id],
  slug: 'product-details'
)

Comfy::Cms::Fragment.create!(
  identifier: 'content',
  record: product_details_page,
  tag: 'wysiwyg',
  content: <<~HTML
            <style>
              main {
                padding-top: 40px;
                padding-bottom: 40px;
              }
              .restrictive-container {
                max-width: 1300px;
                margin-left: auto;
                margin-right: auto;
              }
              .product {
                display: grid;
                align-items: start;
                grid-template-columns: 100%;
                gap: 60px;
              }
              .product__variant-title {
                margin-bottom: 4px;
                color: hsla(208, 13%, 45%, 1);
              }
              .product__title {
                margin-right: 20px;
                font-size: clamp(24px, 4.5vw, 40px);
              }
              .product__variant-price {
                font-size: clamp(18px, 4vw, 24px);
              }
              .slick-arrow::before {
                color: black;
              }
              .options-form {
                margin-bottom: 20px;
              }
              .options-container:not(:last-child) {
                margin-bottom: 20px;
              }
              .options {
                display: flex;
                flex-wrap: wrap;
              }
              .option input {
                position: absolute;
                opacity: 0;
                z-index: -1;
              }
              .option label {
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 40px;
                padding: 10px 20px;
                margin-right: 10px;
                margin-bottom: 10px;
                border: 1px solid gray;
                border-radius: 4px;
                cursor: pointer;
              }
              .option input:checked + label {
                outline: 1px solid blue;
              }
              .similar-products-section {
                padding-top: 30px;
                padding-bottom: 30px;
              }
              .similar-products-section__title {
                margin-bottom: 30px;
              }
              .similar-products {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(min(100%, 100px), 1fr));
                gap: 30px;
              }
              .similar-products__link {
                max-width: 350px;
              }
              .similar-products__link img {
                width: 100%;
                border-radius: 8px;
                border: var(--image-border);
              }
              @media only screen and (min-width: 1000px) {
                .product {
                  grid-template-columns: 43% 50%;
                }
              }
            </style>
            <main>
              <div class="restrictive-container">{{ cms:helper render_api_namespace_resource 'products', scope: { properties: { visible: 'true' } } }}
              </div>
            </main>
            <div class="toast-container">
            </div>
            <script>{{ cms:snippet product-details-script }}
            </script>
          HTML
)

cart_page = layout.pages.create!(
  site_id: site.id,
  label: 'cart',
  category_ids: [page_category.id],
  slug: 'cart'
)

Comfy::Cms::Fragment.create!(
  identifier: 'content',
  record: cart_page,
  tag: 'wysiwyg',
  content:  <<~HTML
            <style>
            h1 {
              margin-bottom: 30px;
            }
            .cart-items-section {
              width: 100%;
              max-width: 650px;
              margin-bottom: 40px;
            }
            .cart-content {
              padding-top: 16px;
              padding-bottom: 16px;
            }
            .cart-content select,
            .cart-content input {
              padding-left: 2px;
              padding-right: 2px;
              border-radius: 4px;
            }
            .cart-item {
              display: flex;
            }
            .cart-item:not(:last-child) {
              margin-bottom: 20px;
            }
            .cart-item__image-container img {
              width: clamp(100px, 22vw, 200px);
            }
            .cart-item__text-content {
              flex-basis: 100%;
            }
            .cart-item__heading {
              display: flex;
              justify-content: space-between;
              align-items: start;
            }
            .btn--remove {
              border: none;
              background-color: transparent;
              margin-left: 20px;
            }
            .btn--remove svg {
              width: 20px;
              height: 20px;
            }
            .cart-item__product-title {
              font-size: 18px;
            }
            .cart-item__variant-title {
              color: var(--gray-text);
              margin-bottom: 0;
            }
            .cart-item__form-controls {
              margin-top: 6px;
              margin-bottom: 10px; 
            }
            .cart-item__options {
              display: flex;
              flex-wrap: wrap;
              margin-bottom: 5px;
            }
            .cart-item__quantity input {
              width: 50px;
            }
            .cart-item__option:not(:last-child) {
              margin-right: 20px;
            }
            .cart-item__price {
              margin-bottom: 0;
            }
            .cart-item__price data {
              font-weight: 600;
            }
            .order-summary {
              min-height: 200px;
            }
            .price-detail {
              display: flex;
              justify-content: space-between;
              font-weight: 600;
              color: var(--gray-text);
            }
            .price-detail data {
              color: var(--default-text);
            }
            .price-detail--subtotal {
              margin-bottom: 0;
            }
            .tax-exclusive-text {
              padding-left: 12px;
              margin-bottom: 0;
              font-size: 13px;
              font-weight: 600;
            }
            .price-detail--shipping {
              margin-top: 10px;
              margin-bottom: 5px;
            }
            .shipping-country select {
              width: 100%;
            }
            .price-detail--convenience {
              margin-bottom: 0;
              margin-top: 6px;
            }
            .price-detail--total {
              margin-top: 30px;
            }
            .btn--checkout {
              display: flex;
              justify-content: center;
              width: 100%;
            }
            .btn--checkout:disabled {
              cursor: not-allowed;
            }
            /* Utilities */
            .section-heading {
              display: flex;
              align-items: center;
              margin-bottom: 20px;
              font-weight: 600;
            }
            .section-title {
              margin-bottom: 0;
              font-size: 18px;
              text-transform: uppercase;
            }
            .section-title__item-count {
              margin-left: 5px;
            }
            .cart-form-control {
              display: flex;
              align-items: start;
              padding-left: 12px;
              font-size: 13px;
            }
            .cart-form-control label {
              margin-right: 5px;
              font-weight: 600;
            }
            /* Media queries */
            @media only screen and (min-width: 650px) {
              .order-summary {
                width: clamp(200px, 26vw, 300px);
              }
            }
            @media only screen and (min-width: 992px) {
              .cart-content {
                display: flex;
                justify-content: space-between;
              }
              .cart-items-section {
                margin-bottom: 0;
                margin-right: 30px;
              }
            }
            </style><main>
            <div class="restrictive-container">
              <h1>Shopping Bag</h1>
              <div class="cart-content">
                <section class="cart-items-section">
                <div class="section-heading">
                  <h2 class="section-title cart-items-section__title">Cart</h2>
                  <div class="section-title__item-count">
                  </div>
                </div>
                <div class="cart-items">
                </div>
                </section><section class="order-summary">
                <div class="section-heading">
                  <h2 class="section-title order-summary__title">Price details</h2>
                  <div class="section-title__item-count">
                  </div>
                </div>
                <div class="order-summary__price-details">
                  <div class="order-summary__loading d-none">
                    <p>Calculating fees...
                    </p>
                  </div>
                  <div class="order-summary__fees">
                    <p class="price-detail price-detail--subtotal">Subtotal: <data value="0.00">$0.00</data>
                    </p>
                    <p class="tax-exclusive-text d-none">Prices are tax exclusive
                    </p>
                    <p class="price-detail price-detail--shipping">Shipping: <data value="0.00">$0.00</data>
                    </p>
                    <div class="shipping-country cart-form-control">
                      <label for="shipping-countries">Country:</label>
                      <select name="shipping-countries" id="shipping-countries" value="CA">
                        <option value="CA">Canada</option>
                        <option value="US">USA</option>
                      </select>
                    </div>
                    <p class="price-detail price-detail--convenience d-none">Convenience fee: <data value="0.00">$0.00</data>
                    </p>
                    <p class="price-detail price-detail--total">Total Amount: <data value="0.00">$0.00</data>
                    </p>
                  </div>
                </div>
                <button type="button" class="btn btn-primary btn--checkout d-none">Checkout</button>
                </section>
              </div>
            </div></main>
            <div class="toast-container">
            </div>
            <script>{{ cms:snippet cart-script }}
            </script>
            HTML
)

checkout_success_page = layout.pages.create!(
  site_id: site.id,
  label: 'checkout-success',
  category_ids: [page_category.id],
  slug: 'checkout-success'
)

Comfy::Cms::Fragment.create!(
  identifier: 'content',
  record: checkout_success_page,
  tag: 'wysiwyg',
  content:  <<~HTML
            <style>
            h1 {
              margin-top: 10px;
            }
            .content-container {
              min-height: 91vh;
              min-height: 91svh;
              display: flex;
              justify-content: center;
              align-items: center;
            }
            .main-content {
              text-align: center;
            }
            .main-content svg {
              width: 150px;
              fill: #0cca81;
            }
            .subtitle {
              margin-bottom: 30px;
            }
            </style><main>
            <div class="restrictive-container content-container">
              <div class="main-content">
                {{ cms:snippet check-icon }}
                <h1>Thank you for your purchase!</h1>
                <p class="subtitle">We have received your order. An automated email with a receipt will be sent to you.
                </p>
                <a class="btn btn-primary" href="/custom-shop">Back to Home</a>
              </div>
            </div></main>
            <script>{{ cms:snippet checkout-success-script }}
            </script>
            HTML
)

p "###################################               SUBSCRIBING TO PRINTIFY WEBHOOKS            ###################################"

subscribe_to_printify_results = []

shop_namespace.reload.api_resources.each do |shop|
  subscribe_to_publish_succeed = HTTParty.post("https://api.printify.com/v1/shops/#{shop.properties['printify_shop_id']}/webhooks.json",
    body: {
      "topic": "product:publish:started",
      "url":  Rails.application.routes.url_helpers.api_external_api_client_webhook_url(version: products_namespace.version, api_namespace: products_namespace.slug, external_api_client: printify_product_publish_plugin.slug, host: ENV['APP_HOST'], protocol: 'https'),
      "secret": WEBHOOK_SECRET
    }.to_json,
    headers: PRINTIFY_HEADERS                
  )

  subscribe_to_printify_results << { shop: shop.properties['title'], success: subscribe_to_publish_succeed.success?, response: JSON.parse(subscribe_to_publish_succeed.body), topic: 'product:publish:started' }

  ['order:created', 'order:updated', 'order:sent-to-production', 'order:shipment:created', 'order:shipment:delivered'].each do |topic|
    subscribe_to_order_status_change = HTTParty.post("https://api.printify.com/v1/shops/#{shop.properties['printify_shop_id']}/webhooks.json",
      body: {
        "topic": topic,
        "url":  Rails.application.routes.url_helpers.api_external_api_client_webhook_url(version: products_namespace.version, api_namespace: products_namespace.slug, external_api_client: order_status_notification_plugin.slug, host: ENV['APP_HOST'], protocol: 'https'),
        "secret": WEBHOOK_SECRET
      }.to_json,
      headers: PRINTIFY_HEADERS
    );
    subscribe_to_printify_results << { shop: shop.properties['title'], success: subscribe_to_order_status_change.success?, response:  JSON.parse(subscribe_to_order_status_change.body), topic: topic }
  end
end

p "###################################             SYNC PRINTIFY PRODUCTS IN BACKGROUND          ###################################"

sync_printify_products_plugin.run

subscribe_to_printify_results

if subscribe_to_printify_results.any? {|res| !res[:success]}
  p ""
  p "[FAILED]: Subscribing to following printify webhook failed. Please subscribe to them manually"
  p ""

  subscribe_to_printify_results.filter {|res| !res[:success]}.each do |res|
    p "     #{res[:topic]} ::- #{res[:response]['errors']['reason']}"
  end
end

p ""
p ""

p "**NEXT STEP**"
p ""
p "     Create a stripe webhhok and add webhook signing secret to the order_fulfill plugin."
p "     DOCS: https://gist.github.com/Pralish/bc3a0441534b32e2d4a189c12b0f061a?permalink_comment_id=4573559#gistcomment-4573559"
p "     You didn't provide STRIPE_SECRET_KEY. Please add the key manually here: #{Rails.application.routes.url_helpers.edit_api_namespace_resource_url(api_namespace_id: printify_account_namespace.id, id: printify_account.id, host: ENV['APP_HOST'])}" unless STRIPE_SECRET_KEY.present?



