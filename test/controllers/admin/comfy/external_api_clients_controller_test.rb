require "test_helper"


class Comfy::Admin::ExternalApiClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_web: true, can_manage_api: true)
    @api_client = api_clients(:one)
    @api_namespace = api_namespaces(:one)
    @external_api_client = external_api_clients(:test)
    
    Sidekiq::Testing.fake!
  end

  test "should allow #start" do
    sign_in(@user)
    @external_api_client.update(status: ExternalApiClient::STATUSES[:stopped], enabled: true)
    previous_state = @external_api_client.reload
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    Sidekiq::Worker.drain_all
  end

  test "should not get index if not authenticated" do
    skip
  end

  test "should not get #index, #new if signed in but not allowed to manage web" do
    skip
  end

  test "should get index" do
    skip
  end

  test "should get new" do
    skip
  end

  test "should create" do
    skip
  end

  test "should show" do
    skip
  end

  test "should get edit" do
    skip
  end

  test "should update" do
    skip
  end

  test "should destroy" do
    skip
  end
end
