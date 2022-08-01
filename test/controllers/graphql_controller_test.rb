require "test_helper"

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subdomain = subdomains(:public)
    @user = users(:public)
    @subdomain.update(graphql_enabled: true)
  end

  test "[if enabled] renders graphiql UI for super/domain admin" do
    @user.update(global_admin: true)
    sign_in(@user)
    get '/admin/graphiql'
    assert_response :success
  end

  test "[if enabled] denies graphiql UI for non super/domain admin" do
    @user.update(global_admin: false)
    sign_in(@user)
    begin
      # this route is not even generated if the user isnt a global admin
      get '/admin/graphiql'
    rescue ActionController::RoutingError => e
      assert_equal "Page Not Found at: \"admin/graphiql\"", e.message
    end
  end

  test "[if enabled] denies graphiql UI if not signed in" do
    begin
      # this route is not even generated if the user isnt a global admin
      get '/admin/graphiql'
    rescue ActionController::RoutingError => e
      assert_equal "Page Not Found at: \"admin/graphiql\"", e.message
    end
  end

  test "[if enabled] query public API Namespaces" do
    query_string = "{ apiNamespaces { id requiresAuthentication } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_equal ["data"], json_response.keys
    assert_equal ["apiNamespaces"], json_response["data"].keys
    sample_api_namespace = json_response["data"]["apiNamespaces"].sample
    assert_equal ["id", "requiresAuthentication"].sort, sample_api_namespace.keys.sort
    assert_equal false, sample_api_namespace["requiresAuthentication"]

    query_string = " { apiNamespaces(limit: 1, offset: 1) { id requiresAuthentication } } "
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_equal ["data"], json_response.keys
  end

  test "[if enabled] query public API Namespaces with nested apiResources" do
    query_string = "{ apiNamespaces(orderDirection: \"desc\", orderDimension: \"updatedAt\") { id apiResources { id } } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_equal ["data"], json_response.keys
  end

  test "[if enabled] query public API Namespaces with nested apiResources with sorting" do
    query_string = "{ apiNamespaces { id apiResources(orderDirection: \"desc\", orderDimension: \"updatedAt\") { id } } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_equal ["data"], json_response.keys
  end

  test "[if enabled] query public API Namespaces with nested apiResources with non-primitive properties" do
    query_string = "{ apiNamespaces { id apiResources { id  nonPrimitiveProperties { url mimeType content }} } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_equal ["data"], json_response.keys
  end

  test "[if enabled] query public API Namespaces with nested apiResources with searching by properties" do
    query_string = "{ apiNamespaces { id apiResources(properties: { name: { value: \"violet\", option: \"PARTIAL\" } }) { id } } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_equal ["data"], json_response.keys
  end

  test "[if enabled] && [if subdomain allows analytics query via API] allows ahoy visit query" do
    @subdomain.update(allow_external_analytics_query: true)
    get root_url
    Ahoy::Visit.first.events.create
    query_string = "{ ahoyVisits { id ip events { id } } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_equal ["data"], json_response.keys
    assert_equal ["ahoyVisits"], json_response["data"].keys
  end

  test "[if enabled] && [if subdomain disallows analytics query via API] raises error for ahoy visit query" do
    @subdomain.update(allow_external_analytics_query: false)
    get root_url
    Ahoy::Visit.first.events.create
    query_string = "{ ahoyVisits { id ip events { id } } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_nil json_response["data"]
  end

  test "[if enabled] && [if subdomain allows analytics query via API] allows ahoy event query" do
    @subdomain.update(allow_external_analytics_query: true)
    get root_url
    Ahoy::Visit.first.events.create
    query_string = "{ ahoyEvents { id visitId } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_equal ["data"], json_response.keys
    assert_equal ["ahoyEvents"], json_response["data"].keys
  end

  test "[if enabled] && [if subdomain disallows analytics query via API] raises error for ahoy event query" do
    @subdomain.update(allow_external_analytics_query: false)
    get root_url
    Ahoy::Visit.first.events.create
    query_string = "{ ahoyEvents { id visitId } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_nil json_response["data"]
  end

  test "[if enabled] && [if subdomain allows analytics query via API] allows ahoy event names query" do
    @subdomain.update(allow_external_analytics_query: true)
    get root_url
    Ahoy::Visit.first.events.create(name: 'foo')
    query_string = "{ ahoyEventNames { name } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_equal ["data"], json_response.keys
    assert_equal ["ahoyEventNames"], json_response["data"].keys
  end

  test "[if enabled] && [if subdomain disallows analytics query via API] raises error for ahoy event names query" do
    @subdomain.update(allow_external_analytics_query: false)
    get root_url
    Ahoy::Visit.first.events.create(name: 'foo')
    query_string = "{ ahoyEventNames { name } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_nil json_response["data"]
  end

  test "[not enabled] presents error" do
    @subdomain.update(graphql_enabled: false)
    query_string = "{ apiNamespaces { id } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert json_response["errors"]
    assert_equal 0, json_response["data"].size
  end
end
