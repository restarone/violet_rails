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
    query_string = "{ apiNamespaces { id } }"
    post '/graphql', params: { query: query_string }
    json_response = JSON.parse(@response.body)
    assert_equal ["data"], json_response.keys
    assert_equal ["apiNamespaces"], json_response["data"].keys
    sample_api_namespace = json_response["data"]["apiNamespaces"].sample
    assert_equal ["id"], sample_api_namespace.keys
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
