require "test_helper"


class Comfy::Admin::ExternalApiClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
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
    @user.update(api_accessibility: {})
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
    @user.update(api_accessibility: {})
    sign_in(@user)

    get new_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id)
    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
  end

  test "#new: allows if permissioned user is signed in" do
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

    @user.update(api_accessibility: {})
    sign_in(@user)

    assert_no_difference "ExternalApiClient.count" do
      post api_namespace_external_api_clients_url(api_namespace_id: @api_namespace.id), params: payload
    end

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
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
    @user.update(api_accessibility: {})
    sign_in(@user)

    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_external_api_connections_only or read_external_api_connections_only are allowed to perform that action."

    assert_response :redirect
    assert_equal expected_message, flash[:alert]
  end

  test "#show: allows if permissioned user is signed in" do
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
    @user.update(api_accessibility: {})
    sign_in(@user)

    get edit_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
  end

  test "#edit: allows if permissioned user is signed in" do
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

    @user.update(api_accessibility: {})
    sign_in(@user)

    patch api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id), params: payload

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_match expected_message, flash[:alert]
    assert_response :redirect
  end

  test "#destroy: denies if user not signed in" do
    assert_no_difference "ExternalApiClient.count" do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end

    expected_message = "You need to sign in or sign up before continuing."

    assert_response :redirect
    assert_redirected_to new_user_session_path
    assert_match expected_message, flash[:alert]
  end

  test "#destroy: denies if user not permissioned to manage api" do
    @user.update(api_accessibility: {})
    sign_in(@user)

    assert_no_difference "ExternalApiClient.count" do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."

    assert_response :redirect
    assert_redirected_to root_path
    assert_match expected_message, flash[:alert]
  end

  test "#destroy: allows if permissioned user is signed in" do
    sign_in(@user)

    assert_difference "ExternalApiClient.count", -1 do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end

    expected_message = "Api client was successfully destroyed."

    assert_response :redirect
    assert_redirected_to api_namespace_external_api_clients_path
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

    @user.update(api_accessibility: {})
    sign_in(@user)

    get stop_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
    assert_not_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
  end

  test "#stop: allows if permissioned user is signed in" do
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running])

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

    @user.update(api_accessibility: {})
    sign_in(@user)

    get clear_errors_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
    assert_not_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
    assert_not_equal 0, @external_api_client.reload.retries
    assert @external_api_client.reload.error_message
    assert @external_api_client.reload.error_metadata
  end

  test "#clear_errors: allows if permissioned user is signed in" do
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], error_message: 'test error message', retries: 3, error_metadata: { 'testKey': 'testMessage'})

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

    @user.update(api_accessibility: {})
    sign_in(@user)

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."

    assert_response :redirect
    assert_match expected_message, flash[:alert]
    assert @external_api_client.reload.state_metadata
  end

  test "#clear_state: allows if permissioned user is signed in" do
    @external_api_client.update(state_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    refute @external_api_client.reload.state_metadata
  end

  # VacuumJob Plugin
  test "#vacuumjob: deletes specified resources succefully" do
    metadata = {
      'ORDER': 'descending',
      'DIMENSION': 'created_at',
      'BATCH_SIZE': '5',
      'API_NAMESPACE_ID': @api_namespace.id,
      'OLDER_THAN': '2880' # 2 days (in minutes)
    }
    vacuum_job_plugin = external_api_clients(:vacuum_job)
    vacuum_job_plugin.update(metadata: metadata)

    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    @api_namespace.api_resources.order(created_at: :desc).limit(3).each { |resource| resource.update_columns(created_at: 5.days.ago) }

    sign_in(@user)

    perform_enqueued_jobs do
      assert_difference 'ApiResource.count', -3 do
        get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: vacuum_job_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end

    assert_response :redirect

    # Specified resources are deleted
    @api_namespace.reload.api_resources.each do |resource|
      assert (Time.zone.now - resource.created_at).minutes.in_minutes < vacuum_job_plugin.metadata['OLDER_THAN'].to_f
    end
  end

  test "#vacuumjob: returns error if resource of another api_namespace is attempted to be deleted" do
    metadata = {
      'ORDER': 'descending',
      'DIMENSION': 'created_at',
      'BATCH_SIZE': '5',
      'API_NAMESPACE_ID': '1',
      'OLDER_THAN': '2880' # 2 days (in minutes)
    }
    vacuum_job_plugin = external_api_clients(:vacuum_job)
    vacuum_job_plugin.update(metadata: metadata)

    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    @api_namespace.api_resources.order(created_at: :desc).limit(3).each { |resource| resource.update_columns(created_at: 5.days.ago) }

    sign_in(@user)

    perform_enqueued_jobs do
      assert_no_difference 'ApiResource.count' do
        get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: vacuum_job_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end

    expected_message = "ApiResource of another ApiNamespace cannot be deleted."

    assert_match expected_message, vacuum_job_plugin.reload.error_message
    assert_response :redirect
  end

  # SHOW
  # API access for all namespaces
  test 'should get show if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :success
  end

  test 'should get show if user has full_read_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_read_access: 'true'}}})

    sign_in(@user)
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :success
  end

  test 'should get show if user has full_access_for_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_external_api_connections_only: 'true'}}})

    sign_in(@user)
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :success
  end

  test 'should get show if user has read_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_external_api_connections_only: 'true'}}})

    sign_in(@user)
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :success
  end

  test 'should not get show if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {allow_duplication: 'true'}}})

    sign_in(@user)
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_external_api_connections_only or read_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get show if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :success
  end

  test 'should get show if user has full_read_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :success
  end

  test 'should get show if user has full_access_for_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :success
  end

  test 'should get show if user has read_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :success
  end

  test 'should get show if user has read_external_api_connections_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {read_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :success
  end

  test 'should not get show if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_duplication: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_external_api_connections_only or read_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # INDEX
  # API access for all namespaces
  test 'should get index if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has full_read_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_read_access: 'true'}}})

    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has full_access_for_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_external_api_connections_only: 'true'}}})

    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has read_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_external_api_connections_only: 'true'}}})

    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should not get index if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {allow_duplication: 'true'}}})

    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_external_api_connections_only or read_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get index if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has full_read_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has full_access_for_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has read_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get index if user has read_external_api_connections_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {read_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should not get index if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_duplication: 'true'}}}})

    sign_in(@user)
    get api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or full_access_for_external_api_connections_only or read_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # NEW
  # API access for all_namespaces
  test 'should get new if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    get new_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get new if user has full_access_for_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_external_api_connections_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should not get new if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_external_api_connections_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get new if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get new if user has full_access_for_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should get new if user has read_external_api_connections_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id)
    assert_response :success
  end

  test 'should not get new if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # EDIT
  # API access for all_namespaces
  test 'should get edit if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :success
  end

  test 'should get edit if user has full_access_for_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_external_api_connections_only: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :success
  end

  test 'should not get edit if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_external_api_connections_only: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get edit if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :success
  end

  test 'should get edit if user has full_access_for_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :success
  end

  test 'should get edit if user has read_external_api_connections_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :success
  end

  test 'should not get edit if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # CREATE
  # API access for all_namespaces
  test 'should get create if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

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

    sign_in(@user)

    assert_difference "ExternalApiClient.count", +1 do
      post api_namespace_external_api_clients_url(api_namespace_id: @api_namespace.id), params: payload
    end

    expected_message = "Api client was successfully created."
    assert_match expected_message, flash[:notice]
    assert_response :redirect
  end

  test 'should get create if user has full_access_for_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_external_api_connections_only: 'true'}}})

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

    sign_in(@user)

    assert_difference "ExternalApiClient.count", +1 do
      post api_namespace_external_api_clients_url(api_namespace_id: @api_namespace.id), params: payload
    end

    expected_message = "Api client was successfully created."
    assert_match expected_message, flash[:notice]
    assert_response :redirect
  end

  test 'should not get create if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_external_api_connections_only: 'true'}}})

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

    sign_in(@user)

    assert_no_difference "ExternalApiClient.count" do
      post api_namespace_external_api_clients_url(api_namespace_id: @api_namespace.id), params: payload
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get create if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

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

    sign_in(@user)

    assert_difference "ExternalApiClient.count", +1 do
      post api_namespace_external_api_clients_url(api_namespace_id: @api_namespace.id), params: payload
    end

    expected_message = "Api client was successfully created."
    assert_match expected_message, flash[:notice]
    assert_response :redirect
  end

  test 'should get create if user has full_access_for_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_external_api_connections_only: 'true'}}}})

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

    sign_in(@user)

    assert_difference "ExternalApiClient.count", +1 do
      post api_namespace_external_api_clients_url(api_namespace_id: @api_namespace.id), params: payload
    end

    expected_message = "Api client was successfully created."
    assert_match expected_message, flash[:notice]
    assert_response :redirect
  end

  test 'should get create if user has read_external_api_connections_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_external_api_connections_only: 'true'}}}})

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

    sign_in(@user)

    assert_difference "ExternalApiClient.count", +1 do
      post api_namespace_external_api_clients_url(api_namespace_id: @api_namespace.id), params: payload
    end

    expected_message = "Api client was successfully created."
    assert_match expected_message, flash[:notice]
    assert_response :redirect
  end

  test 'should not get create if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_external_api_connections_only: 'true'}}}})

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

    sign_in(@user)

    assert_no_difference "ExternalApiClient.count" do
      post api_namespace_external_api_clients_url(api_namespace_id: @api_namespace.id), params: payload
    end
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # UPDATE
  # API access for all_namespaces
  test 'should get update if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

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

    sign_in(@user)

    patch api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id), params: payload

    expected_message = "Api client was successfully updated."
    assert_match expected_message, flash[:notice]
    assert_response :redirect
  end

  test 'should get update if user has full_access_for_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_external_api_connections_only: 'true'}}})

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

    sign_in(@user)

    patch api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id), params: payload

    expected_message = "Api client was successfully updated."
    assert_match expected_message, flash[:notice]
    assert_response :redirect
  end

  test 'should not get update if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_external_api_connections_only: 'true'}}})

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

    sign_in(@user)

    patch api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id), params: payload

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should get update if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

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

    sign_in(@user)

    patch api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id), params: payload

    expected_message = "Api client was successfully updated."
    assert_match expected_message, flash[:notice]
    assert_response :redirect
  end

  test 'should get update if user has full_access_for_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_external_api_connections_only: 'true'}}}})

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

    sign_in(@user)

    patch api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id), params: payload

    expected_message = "Api client was successfully updated."
    assert_match expected_message, flash[:notice]
    assert_response :redirect
  end

  test 'should get update if user has read_external_api_connections_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_external_api_connections_only: 'true'}}}})

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

    sign_in(@user)

    patch api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id), params: payload

    expected_message = "Api client was successfully updated."
    assert_match expected_message, flash[:notice]
    assert_response :redirect
  end

  test 'should not get update if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_external_api_connections_only: 'true'}}}})

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

    sign_in(@user)

    patch api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id), params: payload

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # DESTROY
  # API access for all_namespaces
  test 'should destroy if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)

    assert_difference "ExternalApiClient.count", -1 do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end

    expected_message = "Api client was successfully destroyed."

    assert_response :redirect
    assert_match expected_message, flash[:notice]
  end

  test 'should destroy if user has full_access_for_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_external_api_connections_only: 'true'}}})

    sign_in(@user)

    assert_difference "ExternalApiClient.count", -1 do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end

    expected_message = "Api client was successfully destroyed."

    assert_response :redirect
    assert_match expected_message, flash[:notice]
  end

  test 'should not destroy if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_external_api_connections_only: 'true'}}})

    sign_in(@user)

    assert_no_difference "ExternalApiClient.count" do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should destroy if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)

    assert_difference "ExternalApiClient.count", -1 do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end

    expected_message = "Api client was successfully destroyed."

    assert_response :redirect
    assert_match expected_message, flash[:notice]
  end

  test 'should destroy if user has full_access_for_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_external_api_connections_only: 'true'}}}})

    sign_in(@user)

    assert_difference "ExternalApiClient.count", -1 do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end

    expected_message = "Api client was successfully destroyed."

    assert_response :redirect
    assert_match expected_message, flash[:notice]
  end

  test 'should destroy if user has read_external_api_connections_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_external_api_connections_only: 'true'}}}})

    sign_in(@user)

    assert_difference "ExternalApiClient.count", -1 do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end

    expected_message = "Api client was successfully destroyed."

    assert_response :redirect
    assert_match expected_message, flash[:notice]
  end

  test 'should not destroy if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_external_api_connections_only: 'true'}}}})

    sign_in(@user)

    assert_no_difference "ExternalApiClient.count" do
      delete api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    end
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # START
  # API access for all_namespaces
  test 'should start if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    @external_api_client.update(status: ExternalApiClient::STATUSES[:stopped], enabled: true)
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_not_empty ExternalApiClientJob.jobs
    Sidekiq::Worker.drain_all
  end

  test 'should start if user has full_access_for_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_external_api_connections_only: 'true'}}})

    sign_in(@user)
    @external_api_client.update(status: ExternalApiClient::STATUSES[:stopped], enabled: true)
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_not_empty ExternalApiClientJob.jobs
    Sidekiq::Worker.drain_all
  end

  test 'should not start if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_external_api_connections_only: 'true'}}})

    sign_in(@user)
    @external_api_client.update(status: ExternalApiClient::STATUSES[:stopped], enabled: true)
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_empty ExternalApiClientJob.jobs
    Sidekiq::Worker.drain_all

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should start if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    @external_api_client.update(status: ExternalApiClient::STATUSES[:stopped], enabled: true)
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_not_empty ExternalApiClientJob.jobs
    Sidekiq::Worker.drain_all
  end

  test 'should start if user has full_access_for_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    @external_api_client.update(status: ExternalApiClient::STATUSES[:stopped], enabled: true)
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_not_empty ExternalApiClientJob.jobs
    Sidekiq::Worker.drain_all
  end

  test 'should start if user has read_external_api_connections_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    @external_api_client.update(status: ExternalApiClient::STATUSES[:stopped], enabled: true)
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_not_empty ExternalApiClientJob.jobs
    Sidekiq::Worker.drain_all
  end

  test 'should not start if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_external_api_connections_only: 'true'}}}})

    sign_in(@user)
    @external_api_client.update(status: ExternalApiClient::STATUSES[:stopped], enabled: true)
    get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_empty ExternalApiClientJob.jobs
    Sidekiq::Worker.drain_all

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # STOP
  # API access for all_namespaces
  test 'should stop if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running])

    sign_in(@user)
    get stop_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
  end

  test 'should stop if user has full_access_for_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_external_api_connections_only: 'true'}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running])

    sign_in(@user)
    get stop_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
  end

  test 'should not stop if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_external_api_connections_only: 'true'}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running])

    sign_in(@user)
    get stop_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_not_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should stop if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running])

    sign_in(@user)
    get stop_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
  end

  test 'should stop if user has full_access_for_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_external_api_connections_only: 'true'}}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running])

    sign_in(@user)
    get stop_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
  end

  test 'should stop if user has read_external_api_connections_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_external_api_connections_only: 'true'}}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running])

    sign_in(@user)
    get stop_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
  end

  test 'should not stop if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_external_api_connections_only: 'true'}}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:running])

    sign_in(@user)
    get stop_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)
    assert_response :redirect
    assert_not_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # CLEAR_ERRORS
  # API access for all_namespaces
  test 'should clear_errors if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], error_message: 'test error message', retries: 3, error_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_errors_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
    assert_equal 0, @external_api_client.reload.retries
    refute @external_api_client.reload.error_message
    refute @external_api_client.reload.error_metadata
  end

  test 'should clear_errors if user has full_access_for_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_external_api_connections_only: 'true'}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], error_message: 'test error message', retries: 3, error_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_errors_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
    assert_equal 0, @external_api_client.reload.retries
    refute @external_api_client.reload.error_message
    refute @external_api_client.reload.error_metadata
  end

  test 'should not clear_errors if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_external_api_connections_only: 'true'}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], error_message: 'test error message', retries: 3, error_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_errors_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:error], @external_api_client.reload.status
    assert_equal 3, @external_api_client.reload.retries
    assert @external_api_client.reload.error_message
    assert @external_api_client.reload.error_metadata

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should clear_errors if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], error_message: 'test error message', retries: 3, error_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_errors_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
    assert_equal 0, @external_api_client.reload.retries
    refute @external_api_client.reload.error_message
    refute @external_api_client.reload.error_metadata
  end

  test 'should clear_errors if user has full_access_for_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_external_api_connections_only: 'true'}}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], error_message: 'test error message', retries: 3, error_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_errors_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
    assert_equal 0, @external_api_client.reload.retries
    refute @external_api_client.reload.error_message
    refute @external_api_client.reload.error_metadata
  end

  test 'should clear_errors if user has read_external_api_connections_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_external_api_connections_only: 'true'}}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], error_message: 'test error message', retries: 3, error_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_errors_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:stopped], @external_api_client.reload.status
    assert_equal 0, @external_api_client.reload.retries
    refute @external_api_client.reload.error_message
    refute @external_api_client.reload.error_metadata
  end

  test 'should not clear_errors if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_external_api_connections_only: 'true'}}}})
    @external_api_client.update(status: ExternalApiClient::STATUSES[:error], error_message: 'test error message', retries: 3, error_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_errors_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    assert_equal ExternalApiClient::STATUSES[:error], @external_api_client.reload.status
    assert_equal 3, @external_api_client.reload.retries
    assert @external_api_client.reload.error_message
    assert @external_api_client.reload.error_metadata

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # CLEAR_STATE
  # API access for all_namespaces
  test 'should clear_state if user has full_access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
    @external_api_client.update(state_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    refute @external_api_client.reload.state_metadata
  end

  test 'should clear_state if user has full_access_for_external_api_connections_only for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_external_api_connections_only: 'true'}}})
    @external_api_client.update(state_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    refute @external_api_client.reload.state_metadata
  end

  test 'should not clear_state if user has other access for all namespace' do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {read_external_api_connections_only: 'true'}}})
    @external_api_client.update(state_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    assert @external_api_client.reload.state_metadata

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category wise
  test 'should clear_state if user has full_access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})
    @external_api_client.update(state_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    refute @external_api_client.reload.state_metadata
  end

  test 'should clear_state if user has full_access_for_external_api_connections_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_external_api_connections_only: 'true'}}}})
    @external_api_client.update(state_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    refute @external_api_client.reload.state_metadata
  end

  test 'should clear_state if user has read_external_api_connections_only for the uncategorized namespace' do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_for_external_api_connections_only: 'true'}}}})
    @external_api_client.update(state_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    refute @external_api_client.reload.state_metadata
  end

  test 'should not clear_state if user has other access for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {read_external_api_connections_only: 'true'}}}})
    @external_api_client.update(state_metadata: { 'testKey': 'testMessage'})

    sign_in(@user)

    get clear_state_api_namespace_external_api_client_url(api_namespace_id: @api_namespace.id, id: @external_api_client.id)

    assert_response :redirect
    assert @external_api_client.reload.state_metadata

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_external_api_connections_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end
end
