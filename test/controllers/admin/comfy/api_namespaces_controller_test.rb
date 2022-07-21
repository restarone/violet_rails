require "test_helper"

class Comfy::Admin::ApiNamespacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(can_manage_api: true)
    @api_namespace = api_namespaces(:one)
  end

  test "should not get index if not logged in" do
    get api_namespaces_url
    assert_redirected_to new_user_session_url
  end

  test "should not get index if signed in but not allowed to manage api" do
    sign_in(@user)
    @user.update(can_manage_api: false)
    get api_namespaces_url
    assert_response :redirect
  end

  test "should get index" do
    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  test "should get new" do
    sign_in(@user)
    get new_api_namespace_url
    assert_response :success
  end

  test "should create api_namespace" do
    sign_in(@user)
    assert_difference('ApiNamespace.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
    api_namespace = ApiNamespace.last
    assert api_namespace.slug
    assert_redirected_to api_namespace_url(api_namespace)
  end

  test "should show api_namespace" do
    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should get edit" do
    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should update api_namespace" do
    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_redirected_to api_namespace_url(@api_namespace)
  end

  test "should destroy api_namespace" do
    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should create api_form if has_form params is true" do
    sign_in(@user)
    assert_difference('ApiForm.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, has_form: "1" ,requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
    api_namespace = ApiNamespace.last
    assert api_namespace.api_form
  end

  test "should create set type validation to tel if value is an Integer" do
    sign_in(@user)
    properties = {
      "name": 'test',
      "age": 25
    }.to_json

    assert_difference('ApiForm.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: properties, has_form: "1" ,requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
    api_namespace = ApiNamespace.last
    assert api_namespace.api_form
    assert_equal api_namespace.api_form.properties["age"]["type_validation"], 'tel'
  end

  test "should create api_form if has_form params is true when updating" do
    sign_in(@user)
    assert_difference('ApiForm.count') do
      patch api_namespace_url(api_namespaces(:two)), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, has_form: '1', properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
  end

  test "should reomve api_form if has_form params is false when updating" do
    sign_in(@user)
    assert_difference('ApiForm.count', -1) do
      patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, has_form: '0', properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
  end

  test "should not create api_form if api_form already exists" do
    sign_in(@user)
    assert_no_difference('ApiForm.count') do
      patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, has_form: '1', properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
  end

  test "should rerun all failed action" do
    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size", -(failed_action_counts) do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
      assert_response :redirect
    end
  end

  test "should change all failed action to discarded" do
    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size", -(failed_action_counts) do
      assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'discarded').size", failed_action_counts do
        post discard_failed_api_actions_api_namespace_url(@api_namespace)
      end
    end
  end

  test "should not allow duplicate_without_associations if not allowed to manage api" do
    api_form = api_forms(:one)
    @user.update(can_manage_api: false)

    sign_in(@user)
    
    post duplicate_without_associations_api_namespace_url(id: @api_namespace.id)
    assert_response :redirect
    
    error_message = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."
    assert_match error_message, request.flash[:alert]
  end

  test "should not allow duplicate_without_associations if api_namespace has api_form" do
    api_form = api_forms(:one)

    sign_in(@user)
    assert_no_difference('ApiNamespace.count') do
      assert_no_difference('ApiResource.count') do
        assert_no_difference('ApiAction.count') do
          assert_no_difference('ApiClient.count') do
            assert_no_difference('ExternalApiClient.count') do
              assert_no_difference('NonPrimitiveProperty.count') do
                post duplicate_without_associations_api_namespace_url(id: @api_namespace.id)
                assert_response :redirect
              end
            end
          end
        end
      end
    end

    error_message = "Duplicating Api namespace failed due to: You cannot duplicate the api_namespace without associations if it has api_form."
    assert_match error_message, request.flash[:alert]
  end

  test "should allow duplicate_without_associations if api_namespace does not have api_form" do
    @api_namespace.api_form.destroy

    sign_in(@user)
    assert_difference('ApiNamespace.count', +1) do
      assert_no_difference('ApiResource.count') do
        assert_no_difference('ApiAction.count') do
          assert_no_difference('ApiClient.count') do
            assert_no_difference('ExternalApiClient.count') do
              assert_no_difference('NonPrimitiveProperty.count') do
                post duplicate_without_associations_api_namespace_url(id: @api_namespace.id)
                assert_response :redirect
              end
            end
          end
        end
      end
    end

    success_message = "Api namespace was successfully created."
    assert_match success_message, request.flash[:notice]
  end

  test "should not allow duplicate_with_associations if not allowed to manage api" do
    api_form = api_forms(:one)
    @user.update(can_manage_api: false)

    sign_in(@user)
    
    post duplicate_with_associations_api_namespace_url(id: @api_namespace.id)
    assert_response :redirect
    
    error_message = "You do not have the permission to do that. Only users who can_manage_api are allowed to perform that action."
    assert_match error_message, request.flash[:alert]
  end

  test "should allow duplicate_with_associations" do
    api_resources_count = @api_namespace.api_resources.count
    api_actions_count = @api_namespace.api_actions.count + @api_namespace.api_resources.map(&:api_actions).flatten.count
    api_clients_count = @api_namespace.api_clients.count
    external_api_clients_count = @api_namespace.external_api_clients.count
    non_primitive_properties_count = @api_namespace.non_primitive_properties.count

    sign_in(@user)
    assert_difference('ApiNamespace.count', +1) do
      assert_difference('ApiResource.count', +api_resources_count) do
        assert_difference('ApiAction.count', +api_actions_count) do
          assert_difference('ApiClient.count', +api_clients_count) do
            assert_difference('ExternalApiClient.count', +external_api_clients_count) do
              assert_difference('NonPrimitiveProperty.count', +non_primitive_properties_count) do
                post duplicate_with_associations_api_namespace_url(id: @api_namespace.id)
                assert_response :redirect
              end
            end
          end
        end
      end
    end

    success_message = "Api namespace was successfully created."
    assert_match success_message, request.flash[:notice]
  end

  test "should export api_namespace" do
    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should deny export api_namespace without associations as JSON if user is not authorized" do
    @user.update(can_manage_api: false)
    sign_in(@user)
    get export_without_associations_as_json_api_namespace_url(@api_namespace)
    assert_response :redirect
  end

  test "should export api_namespace without associations as JSON" do
    sign_in(@user)
    get export_without_associations_as_json_api_namespace_url(@api_namespace)
    expected_output = @api_namespace.to_json(root: 'api_namespace')
    assert_response :success
    assert_equal response.body, expected_output
  end

  test "should deny export api_namespace with associations as JSON if user is not authorized" do
    @user.update(can_manage_api: false)
    sign_in(@user)
    get export_with_associations_as_json_api_namespace_url(@api_namespace)
    assert_response :redirect
  end

  test "should export api_namespace with associations as JSON" do
    sign_in(@user)
    get export_with_associations_as_json_api_namespace_url(@api_namespace)
    expected_output = @api_namespace.to_json(
      root: 'api_namespace',
      include: [
        :api_form,
        :api_clients,
        :external_api_clients,
        :non_primitive_properties,
        {
          api_actions: {
            except: [:salt, :encrypted_bearer_token],
            methods: [:bearer_token, :type]
          }
        },
        {
          api_resources: {
            include: [
              {
                api_actions: {
                  except: [:salt, :encrypted_bearer_token],
                  methods: [:bearer_token, :type]
                }
              }
            ]
          }
        }
      ]
    )
    assert_response :success
    assert_equal response.body, expected_output
  end

  test "should deny import api_namespace provided as json if user is not authorized" do
    json_file = Tempfile.new(['api_namespace.json', '.json'])
    json_file.write(@api_namespace.export_as_json(include_associations: false))
    json_file.rewind

    payload = {
      file: fixture_file_upload(json_file.path, 'application/json')
    }

    @user.update(can_manage_api: false)
    sign_in(@user)
    assert_no_difference('ApiNamespace.count') do
      assert_no_difference('ApiResource.count') do
        assert_no_difference('ApiAction.count') do
          assert_no_difference('ApiClient.count') do
            assert_no_difference('ExternalApiClient.count') do
              assert_no_difference('NonPrimitiveProperty.count') do
                post import_as_json_api_namespaces_url, params: payload
                assert_response :redirect
              end
            end
          end
        end
      end
    end
  end

  test "should not import api_namespace provided as json if file content is not proper json" do
    json_file = Tempfile.new(['api_namespace.json', '.json'])
    json_file.write('testing non json content.')
    json_file.rewind

    payload = {
      file: fixture_file_upload(json_file.path, 'application/json')
    }

    sign_in(@user)
    assert_no_difference('ApiNamespace.count') do
      assert_no_difference('ApiResource.count') do
        assert_no_difference('ApiAction.count') do
          assert_no_difference('ApiClient.count') do
            assert_no_difference('ExternalApiClient.count') do
              assert_no_difference('NonPrimitiveProperty.count') do
                post import_as_json_api_namespaces_url, params: payload
                assert_response :redirect
              end
            end
          end
        end
      end
    end

    expected_message = "Importing Api namespace failed due to"
    assert_match expected_message, flash[:alert]
  end

  test "should allow import api_namespace provided as json without asscociations and the newly created api_namespace should be followed by secure-random if api_namespace with such name exists" do
    json_file = Tempfile.new(['api_namespace.json', '.json'])
    json_file.write(@api_namespace.export_as_json(include_associations: false))
    json_file.rewind

    payload = {
      file: fixture_file_upload(json_file.path, 'application/json')
    }

    sign_in(@user)
    assert_difference('ApiNamespace.count', +1) do
      assert_no_difference('ApiResource.count') do
        assert_no_difference('ApiAction.count') do
          assert_no_difference('ApiClient.count') do
            assert_no_difference('ExternalApiClient.count') do
              assert_no_difference('NonPrimitiveProperty.count') do
                post import_as_json_api_namespaces_url, params: payload
                assert_response :redirect
              end
            end
          end
        end
      end
    end

    success_message = "Api namespace was successfully imported."
    assert_match success_message, request.flash[:notice]
    assert_not_equal @api_namespace.name, ApiNamespace.last.name
    assert_match @api_namespace.name, ApiNamespace.last.name
  end

  test "should allow import api_namespace provided as json with its asscociations and the newly created api_namespace should be followed by secure-random if api_namespace with such name exists" do
    api_resources_count = @api_namespace.api_resources.count
    api_actions_count = @api_namespace.api_actions.count + @api_namespace.api_resources.map(&:api_actions).flatten.count
    api_clients_count = @api_namespace.api_clients.count
    external_api_clients_count = @api_namespace.external_api_clients.count
    non_primitive_properties_count = @api_namespace.non_primitive_properties.count

    json_file = Tempfile.new(['api_namespace.json', '.json'])
    json_file.write(@api_namespace.export_as_json(include_associations: true))
    json_file.rewind

    payload = {
      file: fixture_file_upload(json_file.path, 'application/json')
    }

    sign_in(@user)
    assert_difference('ApiNamespace.count', +1) do
      assert_difference('ApiResource.count', +api_resources_count) do
        assert_difference('ApiAction.count', +api_actions_count) do
          assert_difference('ApiClient.count', +api_clients_count) do
            assert_difference('ExternalApiClient.count', +external_api_clients_count) do
              assert_difference('NonPrimitiveProperty.count', +non_primitive_properties_count) do
                post import_as_json_api_namespaces_url, params: payload
                assert_response :redirect
              end
            end
          end
        end
      end
    end

    success_message = "Api namespace was successfully imported."
    assert_match success_message, request.flash[:notice]
    assert_not_equal @api_namespace.name, ApiNamespace.last.name
    assert_match @api_namespace.name, ApiNamespace.last.name
  end

  test "should allow import api_namespace provided as json with its asscociations and the newly created api_namespace's name should be as provided if api_namespace with such name does not exist" do
    api_resources_count = @api_namespace.api_resources.count
    api_actions_count = @api_namespace.api_actions.count + @api_namespace.api_resources.map(&:api_actions).flatten.count
    api_clients_count = @api_namespace.api_clients.count
    external_api_clients_count = @api_namespace.external_api_clients.count
    non_primitive_properties_count = @api_namespace.non_primitive_properties.count

    json_file = Tempfile.new(['api_namespace.json', '.json'])
    api_namespace_hash = JSON.parse(@api_namespace.export_as_json(include_associations: true))
    api_namespace_hash['api_namespace']['name'] = 'testing-import-api-namespace'
    api_namespace_hash['api_namespace']['slug'] = 'testing-import-api-namespace'
    json_file.write(api_namespace_hash.to_json)
    json_file.rewind

    payload = {
      file: fixture_file_upload(json_file.path, 'application/json')
    }

    sign_in(@user)
    assert_difference('ApiNamespace.count', +1) do
      assert_difference('ApiResource.count', +api_resources_count) do
        assert_difference('ApiAction.count', +api_actions_count) do
          assert_difference('ApiClient.count', +api_clients_count) do
            assert_difference('ExternalApiClient.count', +external_api_clients_count) do
              assert_difference('NonPrimitiveProperty.count', +non_primitive_properties_count) do
                post import_as_json_api_namespaces_url, params: payload
                assert_response :redirect
              end
            end
          end
        end
      end
    end

    success_message = "Api namespace was successfully imported."
    assert_match success_message, request.flash[:notice]
    assert_equal api_namespace_hash['api_namespace']['name'], ApiNamespace.last.name
  end

  test "should allow #show and the dynamic properties should be shown in the api-resources tables" do
    sign_in(@user)
    properties = {"attr_1"=>true, "attr_2"=>true, "attr_3"=>true, "attr_4"=>true}

    @api_namespace.has_form = '1'
    @api_namespace.update(properties: properties)

    get api_namespace_url(@api_namespace)
    assert_response :success

    assert_select "table", 1, "This page must contain a api-resources table"
    properties.keys.each do |heading|
      assert_select "thead th", {count: 1, text: heading}, "Api-resources table must contain '#{heading}' column"
    end
  end
end
