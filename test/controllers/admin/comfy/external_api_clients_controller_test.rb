require "test_helper"


class Comfy::Admin::ExternalApiClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_api: true)
    @api_client = api_clients(:one)
    @api_namespace = api_namespaces(:one)
    @external_api_client = external_api_clients(:test)
    
    Sidekiq::Testing.fake!
  end

  test "should allow #start" do
    sign_in(@user)
    @external_api_client.update(status: ExternalApiClient::STATUSES[:stopped], enabled: true)
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_not_empty ExternalApiClientJob.jobs
    Sidekiq::Worker.drain_all
  end

  test "#start: should not run sidekiq-job if external-api-client is disabled" do
    @external_api_client.update(status: ExternalApiClient::STATUSES[:stopped], enabled: false)
    
    sign_in(@user)
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    
    assert_response :redirect
    assert_empty ExternalApiClientJob.jobs
  
    Sidekiq::Worker.drain_all
  end

  test "#start: should not run sidekiq-job if external-api-client is in error status" do
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], enabled: true)
    
    sign_in(@user)
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    
    assert_response :redirect
    assert_empty ExternalApiClientJob.jobs
  
    Sidekiq::Worker.drain_all
  end

  test "#start: should not run sidekiq-job if external-api-client is in running status" do
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running], enabled: true)
    
    sign_in(@user)
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    
    assert_response :redirect
    assert_empty ExternalApiClientJob.jobs
  
    Sidekiq::Worker.drain_all
  end

  test "should not get index if not authenticated" do
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :redirect
  end

  test "should not get #index, if signed in but not allowed to manage api" do
    @user.update(can_manage_api: false)
    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :redirect
  end

  test "should get index" do
    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test "#new: denies if user not signed in" do
    get new_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id)
    expected_message = "You need to sign in or sign up before continuing."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
  end

  test "#new: denies if user not permissioned to manage api" do
    @user.update(can_manage_api: false)
    sign_in(@user)

    get new_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id)
    expected_message = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
  end

  test "#new: allows if permissioned user is signed in" do
    @user.update(can_manage_api: true)
    sign_in(@user)

    get new_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id)

    assert_response :success
  end

  test "#create: should allow when permissioned user is signed-in and sets only the permitted atrributes" do
    payload = {
      external_api_client: {
        api_namespace_id: @api_namespace.id,
        label: 'Create Test API',
        enabled: true,
        metadata: {
                    "api_key": "x-api-key-foo",
                    "bearer_token": "foo",
                    "test_object": {'a': 'test string', 'b': [1,2,3]}
                  }.to_json,
        state_metadata: {
                    "api_key": "x-api-key-foo",
                    "bearer_token": "foo",
                    "test_object": {'a': 'test string', 'b': [1,2,3]}
                  }.to_json,
        error_metadata: {
                    "api_key": "x-api-key-foo",
                    "bearer_token": "foo",
                    "test_object": {'a': 'test string', 'b': [1,2,3]}
                  }.to_json,
        model_definition: "class ExternalApiModelExample; def initialize(parameters); # do init stuff; end; def start; return true; end; def log; return true; end; end; # at the end of the file we have to implicitly return the class; ExternalApiModelExample;"
      }
    }

    @user.update(can_manage_api: true)
    sign_in(@user)

    assert_difference "ExternalApiClient.count", +1 do
      post api_namespace_external_api_clients_url(api_namespace_id: @api_namespace.id), params: payload
    end

    expected_message = "Api client was successfully created."
    assert_match expected_message, flash[:notice]
    assert_response :redirect

    new_external_api_client = ExternalApiClient.last

    assert_equal @api_namespace.id, new_external_api_client.api_namespace_id
    assert_equal 'Create Test API', new_external_api_client.label
    assert_equal JSON.parse(payload[:external_api_client][:metadata]), new_external_api_client.metadata
    assert_equal payload[:external_api_client][:model_definition], new_external_api_client.model_definition
    assert new_external_api_client.enabled

    # Should not be set: state_metadata & error_metadata. These are set internally.
    refute new_external_api_client.state_metadata
    refute new_external_api_client.error_metadata
  end

  test "#create: should deny when user is not signed-in" do
    payload = {
      external_api_client: {
        api_namespace_id: @api_namespace.id,
        slug: 'create-test-api',
        label: 'Create Test API',
        enabled: true,
        metadata: {
                    "api_key": "x-api-key-foo",
                    "bearer_token": "foo"
                  },
        model_definition: "class ExternalApiModelExample; def initialize(parameters); # do init stuff; end; def start; return true; end; def log; return true; end; end; # at the end of the file we have to implicitly return the class; ExternalApiModelExample;"
      }
    }

    assert_no_difference "ExternalApiClient.count" do
      post api_namespace_external_api_clients_url(api_namespace_id: @api_namespace.id), params: payload
    end

    expected_message = "You need to sign in or sign up before continuing."
    assert_match expected_message, flash[:alert]
    assert_response :redirect
  end

  test "#create: should deny when user is not permissioned to manage api" do
    payload = {
      external_api_client: {
        api_namespace_id: @api_namespace.id,
        slug: 'create-test-api',
        label: 'Create Test API',
        enabled: true,
        metadata: {
                    "api_key": "x-api-key-foo",
                    "bearer_token": "foo"
                  },
        model_definition: "class ExternalApiModelExample; def initialize(parameters); # do init stuff; end; def start; return true; end; def log; return true; end; end; # at the end of the file we have to implicitly return the class; ExternalApiModelExample;"
      }
    }

    @user.update(can_manage_api: false)
    sign_in(@user)

    assert_no_difference "ExternalApiClient.count" do
      post api_namespace_external_api_clients_url(api_namespace_id: @api_namespace.id), params: payload
    end

    expected_message = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."
    assert_match expected_message, flash[:alert]
    assert_response :redirect
  end

  test "#show: denies if user not signed in" do
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    expected_message = "You need to sign in or sign up before continuing."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
  end

  test "#show: denies if user not permissioned to manage api" do
    @user.update(can_manage_api: false)
    sign_in(@user)

    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    expected_message = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
  end

  test "#show: allows if permissioned user is signed in" do
    @user.update(can_manage_api: true)
    sign_in(@user)

    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :success
  end

  test "#edit: denies if user not signed in" do
    get edit_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    expected_message = "You need to sign in or sign up before continuing."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
  end

  test "#edit: denies if user not permissioned to manage api" do
    @user.update(can_manage_api: false)
    sign_in(@user)

    get edit_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    expected_message = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
  end

  test "#edit: allows if permissioned user is signed in" do
    @user.update(can_manage_api: true)
    sign_in(@user)

    get edit_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :success
  end

  test "#update: should allow when permissioned user is signed-in and sets only the permitted atrributes" do
    payload = {
      external_api_client: {
        api_namespace_id: @api_namespace.id,
        label: 'Update Test API',
        enabled: true,
        metadata: {
                    "api_key": "x-api-key-foo",
                    "bearer_token": "foo",
                    "test_object": {'a': 'test string', 'b': [1,2,3]}
                  }.to_json,
        state_metadata: {
                    "api_key": "x-api-key-foo",
                    "bearer_token": "foo",
                    "test_object": {'a': 'test string', 'b': [1,2,3]}
                  }.to_json,
        error_metadata: {
                    "api_key": "x-api-key-foo",
                    "bearer_token": "foo",
                    "test_object": {'a': 'test string', 'b': [1,2,3]}
                  }.to_json,
        model_definition: "class ExternalApiModelExample; def initialize(parameters); # do init stuff; end; def start; return true; end; def log; return true; end; end; # at the end of the file we have to implicitly return the class; ExternalApiModelExample;"
      }
    }

    @user.update(can_manage_api: true)
    sign_in(@user)

    patch api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id), params: payload

    expected_message = "Api client was successfully updated."
    assert_match expected_message, flash[:notice]
    assert_response :redirect

    @external_api_client.reload

    assert_equal @api_namespace.id, @external_api_client.api_namespace_id
    assert_equal 'Update Test API', @external_api_client.label
    assert_equal JSON.parse(payload[:external_api_client][:metadata]), @external_api_client.metadata
    assert_equal payload[:external_api_client][:model_definition], @external_api_client.model_definition
    assert @external_api_client.enabled

    # Should not be set: state_metadata & error_metadata. These are set internally.
    refute @external_api_client.state_metadata
    refute @external_api_client.error_metadata
  end

  test "#update: should deny when user is not signed-in" do
    payload = {
      external_api_client: {
        api_namespace_id: @api_namespace.id,
        slug: 'create-test-api',
        label: 'Create Test API',
        enabled: true,
        metadata: {
                    "api_key": "x-api-key-foo",
                    "bearer_token": "foo"
                  },
        model_definition: "class ExternalApiModelExample; def initialize(parameters); # do init stuff; end; def start; return true; end; def log; return true; end; end; # at the end of the file we have to implicitly return the class; ExternalApiModelExample;"
      }
    }

    patch api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id), params: payload

    expected_message = "You need to sign in or sign up before continuing."
    assert_match expected_message, flash[:alert]
    assert_response :redirect
  end

  test "#update: should deny when user is not permissioned to manage api" do
    payload = {
      external_api_client: {
        api_namespace_id: @api_namespace.id,
        slug: 'create-test-api',
        label: 'Create Test API',
        enabled: true,
        metadata: {
                    "api_key": "x-api-key-foo",
                    "bearer_token": "foo"
                  },
        model_definition: "class ExternalApiModelExample; def initialize(parameters); # do init stuff; end; def start; return true; end; def log; return true; end; end; # at the end of the file we have to implicitly return the class; ExternalApiModelExample;"
      }
    }

    @user.update(can_manage_api: false)
    sign_in(@user)

    patch api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id), params: payload

    expected_message = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."
    assert_match expected_message, flash[:alert]
    assert_response :redirect
  end

  test "#destroy: denies if user not signed in" do
    assert_no_difference "ExternalApiClient.count" do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end

    expected_message = "You need to sign in or sign up before continuing."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
  end

  test "#destroy: denies if user not permissioned to manage api" do
    @user.update(can_manage_api: false)
    sign_in(@user)

    assert_no_difference "ExternalApiClient.count" do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end

    expected_message = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
  end

  test "#destroy: allows if permissioned user is signed in" do
    @user.update(can_manage_api: true)
    sign_in(@user)

    assert_difference "ExternalApiClient.count", -1 do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end

    expected_message = "Api client was successfully destroyed."

    assert_response :redirect
    assert_match expected_message, flash[:notice]
  end

  test "#stop: denies if user not signed in" do
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running])

    get stop_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    expected_message = "You need to sign in or sign up before continuing."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
    assert_not_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
  end

  test "#stop: denies if user not permissioned to manage api" do
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running])

    @user.update(can_manage_api: false)
    sign_in(@user)

    get stop_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    expected_message = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
    assert_not_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
  end

  test "#stop: allows if permissioned user is signed in" do
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running])

    @user.update(can_manage_api: true)
    sign_in(@user)

    get stop_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
  end

  test "#clear_errors: denies if user not signed in" do
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], error_message: 'test error message', retries: 3, error_metadata: { 'testKey': 'testMessage'})

    get clear_errors_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    expected_message = "You need to sign in or sign up before continuing."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
    assert_not_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
    assert_not_equal 0, @external_api_client.reload.retries
    assert @external_api_client.reload.error_message
    assert @external_api_client.reload.error_metadata
  end

  test "#clear_errors: denies if user not permissioned to manage api" do
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], error_message: 'test error message', retries: 3, error_metadata: { 'testKey': 'testMessage'})

    @user.update(can_manage_api: false)
    sign_in(@user)

    get clear_errors_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    expected_message = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
    assert_not_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
    assert_not_equal 0, @external_api_client.reload.retries
    assert @external_api_client.reload.error_message
    assert @external_api_client.reload.error_metadata
  end

  test "#clear_errors: allows if permissioned user is signed in" do
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], error_message: 'test error message', retries: 3, error_metadata: { 'testKey': 'testMessage'})

    @user.update(can_manage_api: true)
    sign_in(@user)

    get clear_errors_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
    assert_equal 0, @external_api_client.reload.retries
    refute @external_api_client.reload.error_message
    refute @external_api_client.reload.error_metadata
  end

  test "#clear_state: denies if user not signed in" do
    @external_api_client.update(state_metadata: { 'testKey': 'testMessage'})

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    expected_message = "You need to sign in or sign up before continuing."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
    assert @external_api_client.reload.state_metadata
  end

  test "#clear_state: denies if user not permissioned to manage api" do
    @external_api_client.update(state_metadata: { 'testKey': 'testMessage'})

    @user.update(can_manage_api: false)
    sign_in(@user)

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    expected_message = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
    assert @external_api_client.reload.state_metadata
  end

  test "#clear_state: allows if permissioned user is signed in" do
    @external_api_client.update(state_metadata: { 'testKey': 'testMessage'})

    @user.update(can_manage_api: true)
    sign_in(@user)

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    refute @external_api_client.reload.state_metadata
  end
end
