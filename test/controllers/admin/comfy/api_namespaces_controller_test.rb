require "test_helper"

class Comfy::Admin::ApiNamespacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
    @api_namespace = api_namespaces(:one)
  end

  test "should not get index if not logged in" do
    get api_namespaces_url
    assert_redirected_to new_user_session_url
  end

  test "should not get index if signed in but not allowed to manage api" do
    sign_in(@user)
    @user.update(api_accessibility: {})
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
    @user.update(api_accessibility: {})

    sign_in(@user)
    
    post duplicate_without_associations_api_namespace_url(id: @api_namespace.id)
    assert_response :redirect
    
    error_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_duplication are allowed to perform that action."
    assert_match error_message, request.flash[:alert]
  end

  test "should not allow duplicate_without_associations if api_namespace has api_form" do
    api_form = api_forms(:one)

    sign_in(@user)
    assert_no_difference('ApiNamespace.count') do
      assert_no_difference('ApiResource.count') do
        assert_no_difference('ApiAction.count') do
          assert_no_difference('ApiNamespaceKey.count') do
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
          assert_no_difference('ApiNamespaceKey.count') do
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
    @user.update(api_accessibility: {})

    sign_in(@user)
    
    post duplicate_with_associations_api_namespace_url(id: @api_namespace.id)
    assert_response :redirect
    
    error_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_duplication are allowed to perform that action."
    assert_match error_message, request.flash[:alert]
  end

  test "should allow duplicate_with_associations" do
    api_resources_count = @api_namespace.api_resources.count
    api_actions_count = @api_namespace.api_actions.count + @api_namespace.api_resources.map(&:api_actions).flatten.count
    api_namespace_keys_count = @api_namespace.api_namespace_keys.count
    external_api_clients_count = @api_namespace.external_api_clients.count
    non_primitive_properties_count = @api_namespace.non_primitive_properties.count

    sign_in(@user)
    assert_difference('ApiNamespace.count', +1) do
      assert_difference('ApiResource.count', +api_resources_count) do
        assert_difference('ApiAction.count', +api_actions_count) do
          assert_difference('ApiNamespaceKey.count', +api_namespace_keys_count) do
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
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,#{api_namespace.social_share_metadata}\nanalytics_metadata,#{api_namespace.analytics_metadata}\npurge_resources_older_than,never\nassociations,[]\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should export api_resources" do
    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    resource_one = api_resources(:resource_with_all_types_one)
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,api_namespace_id,null,array,number,object,string,boolean,created_at,updated_at,user_id\n" \
    "#{resource_one.id},#{api_namespace.id},#{resource_one.properties['null']},#{resource_one.properties['array']},#{resource_one.properties['number']},\"{\"\"a\"\"=>\"\"apple\"\"}\",#{resource_one.properties['string']},\"\",#{resource_one.created_at},#{resource_one.updated_at},#{resource_one.user_id}\n" \
    "#{resource_two.id},#{api_namespace.id},#{resource_two.properties['null']},#{resource_two.properties['array']},#{resource_two.properties['number']},\"{\"\"b\"\"=>\"\"ball\"\"}\",#{resource_two.properties['string']},\"\",#{resource_two.created_at},#{resource_two.updated_at},#{resource_one.user_id}\n"

    assert_response :success
    assert_equal expected_csv, response.body
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_api_resources_#{DateTime.now.to_i}.csv"
  end

  test "should export api_resources with top-level non-primitive properties" do
    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    api_namespace.non_primitive_properties.create!([
      {
        label: 'file_upload_one',
        field_type: 'file',
      },
      {
        label: 'richtext_field',
        field_type: 'richtext'
      },
      {
        label: 'file_upload_two',
        field_type: 'file',
      }
    ])
    resource_one = api_resources(:resource_with_all_types_one)
    resource_one.non_primitive_properties.create!([
      {
        label: 'file_upload_one',
        field_type: 'file',
        attachment: fixture_file_upload("fixture_image.png", "image/jpeg")
      },
      {
        label: 'richtext_field',
        field_type: 'richtext',
        content: "<div>Hello World</div>"
      },
      {
        label: 'file_upload_two',
        field_type: 'file',
        attachment: fixture_file_upload("fixture_image.png", "image/jpeg")
      }
    ])
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)

    file_upload_one = resource_one.non_primitive_properties.find_by(label: 'file_upload_one').attachment
    file_upload_two = resource_one.non_primitive_properties.find_by(label: 'file_upload_two').attachment
    richtext_field = "\"<div class=\"\"trix-content\"\">\n" \
    "  <div>Hello World</div>\n" \
    "</div>\n\""

    expected_csv = "id,api_namespace_id,null,array,number,object,string,boolean,created_at,updated_at,user_id,file_upload_one,richtext_field,file_upload_two\n" \
    "#{resource_one.id},#{api_namespace.id},#{resource_one.properties['null']},#{resource_one.properties['array']},#{resource_one.properties['number']},\"{\"\"a\"\"=>\"\"apple\"\"}\",#{resource_one.properties['string']},\"\",#{resource_one.created_at},#{resource_one.updated_at},#{resource_one.user_id},#{rails_blob_url(file_upload_one, subdomain: Apartment::Tenant.current)},#{richtext_field},#{rails_blob_url(file_upload_two, subdomain: Apartment::Tenant.current)}\n" \
    "#{resource_two.id},#{api_namespace.id},#{resource_two.properties['null']},#{resource_two.properties['array']},#{resource_two.properties['number']},\"{\"\"b\"\"=>\"\"ball\"\"}\",#{resource_two.properties['string']},\"\",#{resource_two.created_at},#{resource_two.updated_at},#{resource_two.user_id},\"\",\"\",\"\"\n"

    assert_response :success
    assert_equal expected_csv, response.body
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_api_resources_#{DateTime.now.to_i}.csv"
  end

  test "should export api_resources no non-primitive properties if the api-namespace does not have non-primitive properties" do
    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)

    resource_one = api_resources(:resource_with_all_types_one)
    resource_one.non_primitive_properties.create!([
      {
        label: 'file_upload_one',
        field_type: 'file',
        attachment: fixture_file_upload("fixture_image.png", "image/jpeg")
      },
      {
        label: 'richtext_field',
        field_type: 'richtext',
        content: "<div>Hello World</div>"
      },
      {
        label: 'file_upload_two',
        field_type: 'file',
        attachment: fixture_file_upload("fixture_image.png", "image/jpeg")
      }
    ])
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)

    expected_csv = "id,api_namespace_id,null,array,number,object,string,boolean,created_at,updated_at,user_id\n" \
    "#{resource_one.id},#{api_namespace.id},#{resource_one.properties['null']},#{resource_one.properties['array']},#{resource_one.properties['number']},\"{\"\"a\"\"=>\"\"apple\"\"}\",#{resource_one.properties['string']},\"\",#{resource_one.created_at},#{resource_one.updated_at},#{resource_one.user_id}\n" \
    "#{resource_two.id},#{api_namespace.id},#{resource_two.properties['null']},#{resource_two.properties['array']},#{resource_two.properties['number']},\"{\"\"b\"\"=>\"\"ball\"\"}\",#{resource_two.properties['string']},\"\",#{resource_two.created_at},#{resource_two.updated_at},#{resource_two.user_id}\n"

    assert_response :success
    assert_equal expected_csv, response.body
    refute_match 'file_upload_one', response.body
    refute_match 'file_upload_two', response.body
    refute_match 'richtext_field', response.body
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_api_resources_#{DateTime.now.to_i}.csv"
  end

  test "should deny exporting of api-resources as CSV if the user is not authorized" do
    @user.update(api_accessibility: {})
    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)

    assert_response :redirect
    assert_equal "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_exports are allowed to perform that action.", flash[:alert]
  end

  test "should deny export api_namespace without associations as JSON if user is not authorized" do
    @user.update(api_accessibility: {})
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
    @user.update(api_accessibility: {})
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
        },
        {
          api_keys: {
            except: [:salt, :encrypted_token],
            methods: [:token]
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

    @user.update(api_accessibility: {})
    sign_in(@user)
    assert_no_difference('ApiNamespace.count') do
      assert_no_difference('ApiResource.count') do
        assert_no_difference('ApiAction.count') do
          assert_no_difference('ApiNamespaceKey.count') do
            assert_no_difference('ExternalApiClient.count') do
              assert_no_difference('NonPrimitiveProperty.count') do
                post import_as_json_api_namespaces_url, params: payload
                assert_response :redirect
                assert_equal "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only for all_namespaces are allowed to perform that action.", flash[:alert]
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
          assert_no_difference('ApiNamespaceKey.count') do
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

  test "should allow import api_namespace provided as json without associations and the newly created api_namespace should be followed by secure-random if api_namespace with such name exists" do
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
          assert_no_difference('ApiNamespaceKey.count') do
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

  test "should allow import api_namespace provided as json with its associations and the newly created api_namespace should be followed by secure-random if api_namespace with such name exists" do
    api_resources_count = @api_namespace.api_resources.count
    api_actions_count = @api_namespace.api_actions.count + @api_namespace.api_resources.map(&:api_actions).flatten.count
    api_namespace_keys_count = @api_namespace.api_namespace_keys.count
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
          assert_difference('ApiNamespaceKey.count', +api_namespace_keys_count) do
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

  test "should allow import api_namespace provided as json with its associations and the newly created api_namespace's name should be as provided if api_namespace with such name does not exist" do
    api_resources_count = @api_namespace.api_resources.count
    api_actions_count = @api_namespace.api_actions.count + @api_namespace.api_resources.map(&:api_actions).flatten.count
    api_namespace_keys_count = @api_namespace.api_namespace_keys.count
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
          assert_difference('ApiNamespaceKey.count', +api_namespace_keys_count) do
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

    assert_select "table", 2, "This page must contain a api-resources table and external api webhook table"
    properties.keys.each do |heading|
      assert_select "thead th", {count: 1, text: heading.capitalize.gsub('_', ' ')}, "Api-resources table must contain '#{heading}' column"
    end
  end

  test "#index: should show only the api-namespaces with selected categories" do
    api_namespace_one = api_namespaces(:one)
    api_namespace_two = api_namespaces(:two)
    api_namespace_three = api_namespaces(:three)
    api_namespace_four = api_namespaces(:plugin_subdomain_events)

    category_one = comfy_cms_categories(:api_namespace_1)
    category_two = comfy_cms_categories(:api_namespace_2)

    api_namespace_one.update!(category_ids: [category_one.id])
    api_namespace_four.update!(category_ids: [category_one.id])

    sign_in(@user)
    get api_namespaces_url, params: {categories: category_one.label}
    assert_response :success

    categorized_api_namespace_ids = [api_namespace_one.id, api_namespace_four.id]
    @controller.view_assigns['api_namespaces'].each do |api_namespace|
      assert_includes categorized_api_namespace_ids, api_namespace.id
    end
  end

  test "#show: should properly show documentation of urls for REST and Graph interface" do
    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success

    # REST Interface
    assert_select ".tab-content #interface .card .card-body:nth-child(1)" do
      assert_select "h4", { count: 1, text: "REST Interface" }

      assert_select "strong", { count: 1, text: "Request description endpoint:" } do
        assert_select "+ p + pre", { count: 1, text: "#{ApplicationController.helpers.api_base_url(Subdomain.current, @api_namespace)}/describe" }
      end

      assert_select "strong", { count: 1, text: "Request index endpoint:" } do
        assert_select "+ p + pre", { count: 1, text: ApplicationController.helpers.api_base_url(Subdomain.current, @api_namespace) }
      end

      assert_select "strong", { count: 1, text: "Request query endpoint:" } do
        assert_select "+ p + pre", { count: 1, text: "#{ApplicationController.helpers.api_base_url(Subdomain.current, @api_namespace)}/query" }
      end
    end

    # Graph Interface
    assert_select ".tab-content #interface .card .card-body:nth-child(2)" do
      assert_select "h4", { count: 1, text: "Graph Interface" }

      assert_select "strong", { count: 1, text: "Request description endpoint:" } do
        assert_select "+ p + pre", { count: 1, text: "#{ApplicationController.helpers.graphql_base_url(Subdomain.current, @api_namespace)}/describe" }
      end

      assert_select "strong", { count: 1, text: "Request query endpoint:" } do
        assert_select "+ p + pre", { count: 1, text: ApplicationController.helpers.graphql_base_url(Subdomain.current, @api_namespace) }
      end

      assert_select "p", { count: 1, text: "Payload (this)" } do
        assert_select "+ pre", { count: 1, text: "query: { apiNamespaces(slug: \"#{@api_namespace.slug}\") { id } }" }
      end

      assert_select "p", { count: 1, text: "Payload (this + children)" } do
        assert_select "+ pre", { count: 1, text: "query: { apiNamespaces(slug: \"#{@api_namespace.slug}\") { id apiResources { id } } }" }
      end

      assert_select "p", { count: 1, text: "Payload (global)" } do
        assert_select "+ pre", { count: 1, text: "query: { apiNamespaces { id } }" }
      end
    end
  end

  test "#show: should allow sorting by dynamic columns" do 
    sign_in(@user)
    api_namespace = api_namespaces(:users)
    api_namespace.update(properties: {
      last_name: "",
      first_name: ""
    })
    api_namespace.api_resources.create!({
      properties: {
        last_name: "Doe",
        first_name: "John",
      }
    })

    assert_equal api_namespace.api_resources.length, 2
    assert_equal api_namespace.api_resources[0].properties['first_name'], "Don"
    assert_equal api_namespace.api_resources[1].properties['first_name'], "John"

    get api_namespace_url(api_namespace), params: {q: { s: "first_name desc" }}
    assert_response :success

    assert_select "tbody tr" do |rows|
      assert_includes rows[0].to_s, "John"
      assert_includes rows[1].to_s, "Don"
    end
  end

  test "show# should include the link of associated CMS entities: Page, Snippet and Layout" do
    api_form = api_forms(:one)
    api_form.update!(api_namespace: @api_namespace)

    layout = comfy_cms_layouts(:default)
    page = comfy_cms_pages(:root)
    snippet = comfy_cms_snippets(:public)

    namespace_snippet = @api_namespace.snippet

    layout.update!(content: namespace_snippet)
    snippet.update!(content: namespace_snippet)
    page.fragments.create!(content: namespace_snippet, identifier: 'content')

    sign_in(@user)
    get api_namespace_url(@api_namespace)

    assert_response :success
    assert_select "a[href='#{edit_comfy_admin_cms_site_page_path(site_id: page.site.id, id: page.id)}']", { count: 1 }
    assert_select "a[href='#{edit_comfy_admin_cms_site_snippet_path(site_id: snippet.site.id, id: snippet.id)}']", { count: 1 }
    assert_select "a[href='#{edit_comfy_admin_cms_site_layout_path(site_id: layout.site.id, id: layout.id)}']", { count: 1 }
  end

  test "#index: should show only the api-namespaces with provided properties" do
    plugin_subdomain_events = api_namespaces(:plugin_subdomain_events)
    namespace_with_all_types = api_namespaces(:namespace_with_all_types)
    monitoring_target_incident = api_namespaces(:bishop_monitoring_target_incident)

    sign_in(@user)
    get api_namespaces_url, params: {q: {properties_or_name_cont: 'latency'}}
    assert_response :success

    @controller.view_assigns['api_namespaces'].each do |api_namespace|
      assert_match 'latency', api_namespace.properties.to_s
    end

    refute_includes @controller.view_assigns['api_namespaces'], plugin_subdomain_events
    refute_includes @controller.view_assigns['api_namespaces'], namespace_with_all_types
  end

  test "#index: should show only the api-namespaces with provided name" do
    plugin_subdomain_events = api_namespaces(:plugin_subdomain_events)
    namespace_with_all_types = api_namespaces(:namespace_with_all_types)
    monitoring_target_incident = api_namespaces(:bishop_monitoring_target_incident)

    sign_in(@user)
    get api_namespaces_url, params: {q: {properties_or_name_cont: 'subdomain_events'}}
    assert_response :success

    @controller.view_assigns['api_namespaces'].each do |api_namespace|
      assert_match 'subdomain_events', api_namespace.name
    end
  
    refute_includes @controller.view_assigns['api_namespaces'], namespace_with_all_types
    refute_includes @controller.view_assigns['api_namespaces'], monitoring_target_incident
  end

  test "#index: Rendering tab should include documentation on form snippet and API HTML renderer snippets" do
    sign_in(@user)
    @api_namespace.has_form = "1"
    properties = { test_id: 123, obj:{ a:"b", c:"d"}, title: "Hello World", published: true, arr:[ 1, 2, 3], alpha_arr: ["a", "b"] }

    @api_namespace.update(properties: properties)
    get api_namespace_url(@api_namespace)
    assert_response :success
    assert_select "b", {count: 1, text: "Form rendering snippet:"}
    assert_select "pre", {count: 1, text: @api_namespace.snippet}
    assert_select "b", {count: 1, text: "API HTML Renderer index snippet:"}
    assert_select "pre", {count: 1, text: "{{ cms:helper render_api_namespace_resource_index '#{@api_namespace.slug}', scope: { properties: { arr: [1, 2, 3], obj: { a: \"b\", c: \"d\" }, title: \"Hello World\", test_id: 123, alpha_arr: [\"a\", \"b\"], published: true } } }}"}
    assert_select "b", {count: 1, text: "API HTML Renderer show snippet:"}
    assert_select "pre", {count: 1, text: "{{ cms:helper render_api_namespace_resource '#{@api_namespace.slug}', scope: { properties: { arr: [1, 2, 3], obj: { a: \"b\", c: \"d\" }, title: \"Hello World\", test_id: 123, alpha_arr: [\"a\", \"b\"], published: true } } }}"}
    # Dynamic renderer snippet for KEYWORDS based search
    assert_select "b", {count: 1, text: "API HTML Renderer index snippet (KEYWORDS - works for array and string data type only):"}
    assert_select "pre", {count: 1, text: "{{ cms:helper render_api_namespace_resource_index '#{@api_namespace.slug}', scope: { properties: { arr: { value: [1], option: \"KEYWORDS\" }, title: { value: \"Hello\", option: \"KEYWORDS\" }, alpha_arr: { value: [\"a\"], option: \"KEYWORDS\" } } } }}"}
    assert_select "b", {count: 1, text: "API HTML Renderer show snippet (KEYWORDS - works for array and string data type only):"}
    assert_select "pre", {count: 1, text: "{{ cms:helper render_api_namespace_resource '#{@api_namespace.slug}', scope: { properties: { arr: { value: [1], option: \"KEYWORDS\" }, title: { value: \"Hello\", option: \"KEYWORDS\" }, alpha_arr: { value: [\"a\"], option: \"KEYWORDS\" } } } }}"}
  end

  test "#index: list view should have a Search form" do
    sign_in(@user)
    get api_namespaces_url
    assert_response :success

    assert_select ".list-view form.api_namespace_search", { count: 1 }
  end

  test "#index: list view should include pagination elements" do
    sign_in(@user)
    get api_namespaces_url
    assert_response :success

    assert_select ".list-view .digg_pagination .page-info", { count: 1 }
    assert_select ".list-view .digg_pagination .links", { count: 1 }
  end

  test "#index: list view should have table headings that are sort links" do
    sign_in(@user)
    get api_namespaces_url
    assert_response :success

    assert_select ".list-view table th .sort_link", { count: 1, text: "Name" }
    assert_select ".list-view table th .sort_link", { count: 1, text: "Version" }
    assert_select ".list-view table th .sort_link", { count: 1, text: "Properties" }
    assert_select ".list-view table th .sort_link", { count: 1, text: "Requires authentication" }
    assert_select ".list-view table th .sort_link", { count: 1, text: "Namespace type" }
    assert_select ".list-view table th .sort_link", { count: 1, text: "Cms associations" }
  end

  test "#index: should paginate API namespaces" do
    items_per_page = 10

    sign_in(@user)
    get api_namespaces_url
    assert_response :success

    assert_equal items_per_page, @controller.view_assigns['api_namespaces'].length
  end

  test "#index: should paginate sorted API namespaces" do
    items_per_page = 10

    sign_in(@user)
    get api_namespaces_url, params: { q: { s: 'name asc' } }
    assert_response :success

    assert_equal items_per_page, @controller.view_assigns['api_namespaces'].length
  end

  test "#index: should allow searching by name" do
    searchTerm = 'clients'

    sign_in(@user)
    get api_namespaces_url, params: { q: { properties_or_name_cont: searchTerm } }

    @controller.view_assigns['api_namespaces_q'].result.each do |namespace|
      assert namespace.name.include? searchTerm
    end
  end

  test "#index: should allow searching by property value" do
    searchTerm = 'first_name'

    sign_in(@user)
    get api_namespaces_url, params: { q: { properties_or_name_cont: searchTerm } }

    @controller.view_assigns['api_namespaces_q'].result.each do |namespace|
      assert namespace.properties.to_s.include? searchTerm
    end
  end

  test "#index: should allow sorting by CMS associations count in ascending order" do
    # All namespaces have no cms associations by default
    api_form = api_forms(:one)
    api_form.update!(api_namespace: @api_namespace)
    root_page = comfy_cms_pages(:root)
    namespace_snippet = @api_namespace.snippet

    # root page will be a CMS association of @api_namespace since the namespace's form is being rendered there
    root_page.fragments.create!(content: namespace_snippet, identifier: 'content')

    # Need the last page number to assert that @api_namespace is the very last item
    # Since @api_namespace is the only namespace with a CMS association, it will be the last item on the last page
    items_per_page = 10.0
    last_page_number = (ApiNamespace.all.length / items_per_page).ceil

    sign_in(@user)
    get api_namespaces_url, params: { page: last_page_number.to_s, q: { s: 'CMS asc' } }
    assert_response :success

    assert_select '.list-view tbody tr' do |rows|
      assert_includes rows[rows.length - 1].to_s, @api_namespace.name
    end
  end

  test "#index: should allow sorting by CMS associations count in descending order" do
    api_form = api_forms(:one)
    api_form.update!(api_namespace: @api_namespace)
    root_page = comfy_cms_pages(:root)
    namespace_snippet = @api_namespace.snippet

    root_page.fragments.create!(content: namespace_snippet, identifier: 'content')

    sign_in(@user)
    get api_namespaces_url, params: { q: { s: 'CMS desc' } }
    assert_response :success

    # Since @api_namespace is the only namespace with a CMS association, it will be the very first list item
    assert_select '.list-view tbody tr' do |rows|
      assert_includes rows[0].to_s, @api_namespace.name
    end
  end

  test "#index: should render table partial in case of a turbo frame request" do
    sign_in(@user)
    get api_namespaces_url, headers: { 'Turbo-Frame' => 'api-namespaces' }
    assert_response :success

    assert_template partial: 'comfy/admin/api_namespaces/_table'
  end

  ######## API Accessibility Tests - START #########

  # INDEX
  # API access for all_namespaces
  test "should get index if user has full_access for all namespaces" do
    sign_in(@user)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has full_read_access for all namespaces" do
    sign_in(@user)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_read_access: 'true'}}})
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has full_access_api_namespace_only for all namespaces" do
    sign_in(@user)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has other access for all namespaces" do
    sign_in(@user)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {allow_exports: 'true'}}})
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has allow_social_share_metadata access for all namespaces" do
    sign_in(@user)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {allow_social_share_metadata: 'true'}}})
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has other access related to api-actions/api-resources/api-clients/api-form/external-api-connection for all namespaces" do
    ['read_api_resources_only', 'full_access_for_api_resources_only', 'delete_access_for_api_resources_only', 'read_api_actions_only', 'full_access_for_api_actions_only', 'read_external_api_connections_only', 'full_access_for_external_api_connections_only', 'read_api_clients_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {all_namespaces: {}}}
      access[:api_namespaces][:all_namespaces][access_name] = 'true'

      @user.update(api_accessibility: access)

      sign_in(@user)
      get api_namespaces_url
      assert_response :success
    end
  end

  test "should get index if user has access only related to api-keys" do
    ['full_access', 'delete_access', 'read_access'].each do |access_name|
      access = {api_keys: {}}
      access[:api_keys][access_name] = 'true'

      @user.update(api_accessibility: access)

      sign_in(@user)
      get api_namespaces_url
      assert_response :success
    end
  end

  test "should get index with all namespaces if user has access for all_namespaces" do
    sign_in(@user)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {allow_exports: 'true'}}})
    get api_namespaces_url
    assert_response :success

    # All the ApiNamespaces are fetched in controller.
    all_namespaces = @controller.view_assigns['api_namespaces_q'].result
    ApiNamespace.all.each do |namespace|
      assert_includes all_namespaces, namespace
    end
  end

  # API access by category
  test "should get index if user has category specific full_access for one of the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has category specific full_read_access for one of the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}}})

    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has category specific full_access_api_namespace_only for one of the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}}})

    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has category specific other access for one of the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}}})

    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has category-specific allow_social_share_metadata access for one of the namespaces" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_social_share_metadata: 'true'}}}})

    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has uncategorized allow_social_share_metadata access for one of the namespaces" do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {allow_social_share_metadata: 'true'}}}})

    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has other category specific access related to api-actions/api-resources/api-clients/api-form/external-api-connection for namespaces" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    ['read_api_resources_only', 'full_access_for_api_resources_only', 'delete_access_for_api_resources_only', 'read_api_actions_only', 'full_access_for_api_actions_only', 'read_external_api_connections_only', 'full_access_for_external_api_connections_only', 'read_api_clients_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {}}}
      access[:api_namespaces][:namespaces_by_category][category.label] = {}
      access[:api_namespaces][:namespaces_by_category][category.label][access_name] = 'true'

      @user.update(api_accessibility: access)

      sign_in(@user)
      get api_namespaces_url
      assert_response :success
    end
  end

  test "should get index with only the uncategorized namespaces if user has category-specific for uncategorized namespaces" do
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace_two = api_namespaces(:two)

    # Only two namespaces are uncategorized.
    ApiNamespace.where.not(id: [@api_namespace.id, api_namespace_two.id]).each do |namespace|
      namespace.update(category_ids: [category.id])
    end
    
    sign_in(@user)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {allow_exports: 'true'}}}})
    get api_namespaces_url
    assert_response :success

    all_namespaces = @controller.view_assigns['api_namespaces_q'].result
    # Only the uncategorized ApiNamespaces are fetched in controller.
    [@api_namespace, api_namespace_two].each do |namespace|
      assert_includes all_namespaces, namespace
    end
    # The api-namespaces which are categorized are not fetched. 
    ApiNamespace.where.not(id: [@api_namespace.id, api_namespace_two.id]).each do |namespace|
      refute_includes all_namespaces, namespace
    end
  end

  test "should get index with only the uncategorized and provided category namespaces if user has category-specific for uncategorized and some categorized namespaces" do
    category_one = comfy_cms_categories(:api_namespace_1)
    category_two = comfy_cms_categories(:api_namespace_2)

    api_namespace_two = api_namespaces(:two)
    api_namespace_three = api_namespaces(:three)
    api_namespace_four = api_namespaces(:users)
    api_namespace_five = api_namespaces(:array_namespace)
    api_namespace_six = api_namespaces(:plugin_subdomain_events)

    api_namespace_two.update(category_ids: [category_one.id])
    api_namespace_three.update(category_ids: [category_one.id])
    api_namespace_four.update(category_ids: [category_one.id])

    expected_namespaces = [@api_namespace, api_namespace_two, api_namespace_three, api_namespace_four, api_namespace_five, api_namespace_six]

    # Other namespaces are categorized to category_two.
    ApiNamespace.where.not(id: expected_namespaces.map(&:id)).each do |namespace|
      namespace.update(category_ids: [category_two.id])
    end
    
    sign_in(@user)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {allow_exports: 'true'}, "#{category_one.label}": {allow_exports: 'true'}}}})
    get api_namespaces_url
    assert_response :success

    all_namespaces = @controller.view_assigns['api_namespaces_q'].result
    # Only the uncategorized & category_one ApiNamespaces are fetched in controller.
    expected_namespaces.each do |namespace|
      assert_includes all_namespaces, namespace
    end
    # The api-namespaces which are categorized are not fetched. 
    ApiNamespace.where.not(id: expected_namespaces.map(&:id)).each do |namespace|
      refute_includes all_namespaces, namespace
    end
  end

  test "should get index with only provided category namespaces if user has category-specific for some categorized namespaces" do
    category_one = comfy_cms_categories(:api_namespace_1)
    category_two = comfy_cms_categories(:api_namespace_2)

    api_namespace_two = api_namespaces(:two)
    api_namespace_three = api_namespaces(:three)
    api_namespace_four = api_namespaces(:users)
    api_namespace_five = api_namespaces(:array_namespace)
    api_namespace_six = api_namespaces(:plugin_subdomain_events)

    api_namespace_two.update(category_ids: [category_one.id])
    api_namespace_three.update(category_ids: [category_one.id])
    api_namespace_four.update(category_ids: [category_one.id])

    @api_namespace.update(category_ids: [category_two.id])
    api_namespace_five.update(category_ids: [category_two.id])
    api_namespace_six.update(category_ids: [category_two.id])
    # Other namespaces are uncategorized.

    expected_namespaces = [@api_namespace, api_namespace_two, api_namespace_three, api_namespace_four, api_namespace_five, api_namespace_six]

    sign_in(@user)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category_two.label}": {allow_exports: 'true'}, "#{category_one.label}": {allow_exports: 'true'}}}})
    get api_namespaces_url
    assert_response :success

    all_namespaces = @controller.view_assigns['api_namespaces_q'].result
    # Only the category_one & category_two ApiNamespaces are fetched in controller.
    expected_namespaces.each do |namespace|
      assert_includes all_namespaces, namespace
    end
    # The api-namespaces which are uncategorized are not fetched. 
    ApiNamespace.where.not(id: expected_namespaces.map(&:id)).each do |namespace|
      refute_includes all_namespaces, namespace
    end
  end

  test "should get index if user has other uncategorized access related to api-actions/api-resources/api-clients/api-form/external-api-connection for namespaces" do
    ['read_api_resources_only', 'full_access_for_api_resources_only', 'delete_access_for_api_resources_only', 'read_api_actions_only', 'full_access_for_api_actions_only', 'read_external_api_connections_only', 'full_access_for_external_api_connections_only', 'read_api_clients_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {uncategorized: {}}}}
      access[:api_namespaces][:namespaces_by_category][:uncategorized][access_name] = 'true'

      @user.update(api_accessibility: access)

      sign_in(@user)
      get api_namespaces_url
      assert_response :success
    end
  end

  # NEW
  # API access for all_namespace
  test "should get new if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    get new_api_namespace_url
    assert_response :success
  end

  test "should get new if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_url
    assert_response :success
  end

  test "#new: should show categories when user has proper access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    get new_api_namespace_url
    assert_response :success
    assert_select ".categories-form-partial", {count: 1 }, 'Shows checkboxes to assign categories' do
      # Allows all available categories as options
      Comfy::Cms::Category.of_type('ApiNamespace').each do |category|
        assert_select "label", {count: 1, text: category.label}
      end
    end
  end

  test "should not get new if user has other access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_read_access: 'true'}}})

    sign_in(@user)
    get new_api_namespace_url
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only for all_namespaces are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should not get new if user has access by category wise" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_url
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only for all_namespaces are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should get new if user has full_access for uncategorized api-namespaces" do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_url
    assert_response :success
  end

  test "should get new if user has full_access_api_namespace_only for uncategorized api-namespaces" do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_api_namespace_only: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_url
    assert_response :success
  end

  test "#new: should show categories when user has proper access for namespaces_by_category" do
    api_namespace_1 = comfy_cms_categories(:api_namespace_1)
    api_namespace_2 = comfy_cms_categories(:api_namespace_2)
    api_namespace_3 = comfy_cms_categories(:api_namespace_3)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{api_namespace_1.label}": {full_access: 'true'}, "#{api_namespace_2.label}": {full_access: 'true'}, uncategorized: {full_access: 'true'}}}})

    sign_in(@user)
    get new_api_namespace_url
    assert_response :success
    assert_select ".categories-form-partial", {count: 1 }, 'Shows checkboxes to assign categories' do
      # Shows only the categories as option for which the user has access to.
      assert_select "label", {count: 1, text: api_namespace_1.label}
      assert_select "label", {count: 1, text: api_namespace_2.label}
      assert_select "label", {count: 0, text: api_namespace_3.label}
    end
  end

  # CREATE
  # API access for all_namespace
  test "should create if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
    api_namespace = ApiNamespace.last
    assert api_namespace.slug
    assert_redirected_to api_namespace_url(api_namespace)
  end

  test "should create if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
    api_namespace = ApiNamespace.last
    assert api_namespace.slug
    assert_redirected_to api_namespace_url(api_namespace)
  end

  test "should not create if user has other access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_read_access: 'true'}}})

    sign_in(@user)
    assert_no_difference('ApiNamespace.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
    api_namespace = ApiNamespace.last
    assert api_namespace.slug
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only for all_namespaces are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should not create if user has access by category wise" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    assert_no_difference('ApiNamespace.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
    api_namespace = ApiNamespace.last
    assert api_namespace.slug
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only for all_namespaces are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should create if user has full_access for uncategorized api-namespaces" do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access: 'true'}}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
    api_namespace = ApiNamespace.last
    assert api_namespace.slug
    assert_redirected_to api_namespace_url(api_namespace)
  end

  test "should create if user has full_access_api_namespace_only for uncategorized api-namespaces" do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_api_namespace_only: 'true'}}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
    api_namespace = ApiNamespace.last
    assert api_namespace.slug
    assert_redirected_to api_namespace_url(api_namespace)
  end

  # IMPORT_AS_JSON
  # API access for all_namespace
  test "should import_as_json if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    json_file = Tempfile.new(['api_namespace.json', '.json'])
    json_file.write(@api_namespace.export_as_json(include_associations: false))
    json_file.rewind

    payload = {
      file: fixture_file_upload(json_file.path, 'application/json')
    }

    sign_in(@user)
    assert_difference('ApiNamespace.count', +1) do
      post import_as_json_api_namespaces_url, params: payload
      assert_response :redirect
    end

    success_message = "Api namespace was successfully imported."
    assert_match success_message, request.flash[:notice]
    assert_not_equal @api_namespace.name, ApiNamespace.last.name
    assert_match @api_namespace.name, ApiNamespace.last.name
  end

  test "should import_as_json if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    json_file = Tempfile.new(['api_namespace.json', '.json'])
    json_file.write(@api_namespace.export_as_json(include_associations: false))
    json_file.rewind

    payload = {
      file: fixture_file_upload(json_file.path, 'application/json')
    }

    sign_in(@user)
    assert_difference('ApiNamespace.count', +1) do
      post import_as_json_api_namespaces_url, params: payload
      assert_response :redirect
    end

    success_message = "Api namespace was successfully imported."
    assert_match success_message, request.flash[:notice]
    assert_not_equal @api_namespace.name, ApiNamespace.last.name
    assert_match @api_namespace.name, ApiNamespace.last.name
  end

  test "should not import_as_json if user has other access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_read_access: 'true'}}})

    json_file = Tempfile.new(['api_namespace.json', '.json'])
    json_file.write(@api_namespace.export_as_json(include_associations: false))
    json_file.rewind

    payload = {
      file: fixture_file_upload(json_file.path, 'application/json')
    }

    sign_in(@user)
    assert_no_difference('ApiNamespace.count', +1) do
      post import_as_json_api_namespaces_url, params: payload
      assert_response :redirect
    end

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only for all_namespaces are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should not import_as_json if user has access by category wise" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    json_file = Tempfile.new(['api_namespace.json', '.json'])
    json_file.write(@api_namespace.export_as_json(include_associations: false))
    json_file.rewind

    payload = {
      file: fixture_file_upload(json_file.path, 'application/json')
    }

    sign_in(@user)
    assert_no_difference('ApiNamespace.count', +1) do
      post import_as_json_api_namespaces_url, params: payload
      assert_response :redirect
    end

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only for all_namespaces are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should import_as_json if user has full_access for uncategorized api-namespaces" do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access: 'true'}}}})

    json_file = Tempfile.new(['api_namespace.json', '.json'])
    json_file.write(@api_namespace.export_as_json(include_associations: false))
    json_file.rewind

    payload = {
      file: fixture_file_upload(json_file.path, 'application/json')
    }

    sign_in(@user)
    assert_difference('ApiNamespace.count', +1) do
      post import_as_json_api_namespaces_url, params: payload
      assert_response :redirect
    end

    success_message = "Api namespace was successfully imported."
    assert_match success_message, request.flash[:notice]
    assert_not_equal @api_namespace.name, ApiNamespace.last.name
    assert_match @api_namespace.name, ApiNamespace.last.name
  end

  test "should import_as_json if user has full_access_api_namespace_only for uncategorized api-namespaces" do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_access_api_namespace_only: 'true'}}}})

    json_file = Tempfile.new(['api_namespace.json', '.json'])
    json_file.write(@api_namespace.export_as_json(include_associations: false))
    json_file.rewind

    payload = {
      file: fixture_file_upload(json_file.path, 'application/json')
    }

    sign_in(@user)
    assert_difference('ApiNamespace.count', +1) do
      post import_as_json_api_namespaces_url, params: payload
      assert_response :redirect
    end

    success_message = "Api namespace was successfully imported."
    assert_match success_message, request.flash[:notice]
    assert_not_equal @api_namespace.name, ApiNamespace.last.name
    assert_match @api_namespace.name, ApiNamespace.last.name
  end

  # SHOW
  # API access for all_namespace
  test "should show if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has full_read_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_read_access: 'true'}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show api-resources section if user has full_access or access related to api-resource for all_namespaces" do
    ['full_access', 'full_read_access', 'full_access_for_api_resources_only', 'read_api_resources_only', 'delete_access_for_api_resources_only'].each do |access_name|
      access = {api_namespaces: {all_namespaces: {}}}
      access[:api_namespaces][:all_namespaces][access_name] = 'true'
      @user.update(api_accessibility: access)
  
      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
      assert_select 'div#api-resources-list', {count: 1}
    end
  end

  test "should not show if user has other access for all_namespaces" do
    ['delete_access_api_namespace_only', 'allow_exports', 'allow_duplication', 'allow_social_share_metadata', 'full_access_api_namespace_only', 'read_api_actions_only', 'full_access_for_api_actions_only', 'read_external_api_connections_only', 'full_access_for_external_api_connections_only', 'read_api_clients_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {all_namespaces: {}}}
      access[:api_namespaces][:all_namespaces][access_name] = 'true'
      @user.update(api_accessibility: access)
  
      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
      assert_select 'div#api-resources-list', {count: 0}
    end
  end

  test "should show if user has other access related to namespace for all_namespaces" do
    ['allow_exports', 'allow_duplication', 'allow_social_share_metadata'].each do |access_name|
      access = {api_namespaces: {all_namespaces: {}}}
      access[:api_namespaces][:all_namespaces][access_name] = 'true'
      @user.update(api_accessibility: access)
  
      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
    end
  end

  test "should show if user has other access related to api-actions/api-resources/api-clients/api-form/external-api-connection for all_namespaces" do
    ['read_api_resources_only', 'full_access_for_api_resources_only', 'delete_access_for_api_resources_only', 'read_api_actions_only', 'full_access_for_api_actions_only', 'read_external_api_connections_only', 'full_access_for_external_api_connections_only', 'read_api_clients_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {all_namespaces: {}}}
      access[:api_namespaces][:all_namespaces][access_name] = 'true'

      @user.update(api_accessibility: access)

      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
    end
  end

  # API access by category
  test "should show if user has category specific full_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has category specific full_read_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has category specific other access related to api-actions/api-resources/api-clients/api-form/external-api-connection for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    ['read_api_resources_only', 'full_access_for_api_resources_only', 'delete_access_for_api_resources_only', 'read_api_actions_only', 'full_access_for_api_actions_only', 'read_external_api_connections_only', 'full_access_for_external_api_connections_only', 'read_api_clients_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {}}}
      access[:api_namespaces][:namespaces_by_category][category.label]= {}
      access[:api_namespaces][:namespaces_by_category][category.label][access_name] = 'true'

      @user.update(api_accessibility: access)

      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
    end
  end

  test "should show if user has category-specific other access related to namespace for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    ['allow_exports', 'allow_duplication', 'allow_social_share_metadata'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {}}}
      access[:api_namespaces][:namespaces_by_category][category.label]= {}
      access[:api_namespaces][:namespaces_by_category][category.label][access_name] = 'true'
      @user.update(api_accessibility: access)
  
      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
    end
  end

  test "should show if user has uncategorized access for the namespace with no category" do
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {full_read_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has uncategorized access related to api-actions/api-resources/api-clients/api-form/external-api-connection for the namespace" do
    ['read_api_resources_only', 'full_access_for_api_resources_only', 'delete_access_for_api_resources_only', 'read_api_actions_only', 'full_access_for_api_actions_only', 'read_external_api_connections_only', 'full_access_for_external_api_connections_only', 'read_api_clients_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {uncategorized: {}}}}
      access[:api_namespaces][:namespaces_by_category][:uncategorized][access_name] = 'true'

      @user.update(api_accessibility: access)

      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
    end
  end

  test "should show if user has uncategorized other access related to namespace for the namespace" do
    ['allow_exports', 'allow_duplication', 'allow_social_share_metadata'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {}}}
      access[:api_namespaces][:namespaces_by_category][:uncategorized]= {}
      access[:api_namespaces][:namespaces_by_category][:uncategorized][access_name] = 'true'
      @user.update(api_accessibility: access)
  
      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
    end
  end

  test "should show if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should not show if user has other category specific access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or delete_access_api_namespace_only or allow_exports or allow_duplication or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should show api-resources section if user has category-specific full_access or access related to api-resource for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    ['full_access', 'full_read_access', 'full_access_for_api_resources_only', 'read_api_resources_only', 'delete_access_for_api_resources_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {}}}
      access[:api_namespaces][:namespaces_by_category][:"#{category.label}"]= {}
      access[:api_namespaces][:namespaces_by_category][:"#{category.label}"][access_name] = 'true'
      @user.update(api_accessibility: access)
  
      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
      assert_select 'div#api-resources-list', {count: 1}
    end
  end

  test "should not show if user has other category-specific access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    ['delete_access_api_namespace_only', 'allow_exports', 'allow_duplication', 'allow_social_share_metadata', 'full_access_api_namespace_only', 'read_api_actions_only', 'full_access_for_api_actions_only', 'read_external_api_connections_only', 'full_access_for_external_api_connections_only', 'read_api_clients_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {}}}
      access[:api_namespaces][:namespaces_by_category][:"#{category.label}"]= {}
      access[:api_namespaces][:namespaces_by_category][:"#{category.label}"][access_name] = 'true'
      @user.update(api_accessibility: access)
  
      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
      assert_select 'div#api-resources-list', {count: 0}
    end
  end

  test "should show api-resources section if user has uncategorized full_access or access related to api-resource for the namespace" do
    ['full_access', 'full_read_access', 'full_access_for_api_resources_only', 'read_api_resources_only', 'delete_access_for_api_resources_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {}}}
      access[:api_namespaces][:namespaces_by_category][:uncategorized]= {}
      access[:api_namespaces][:namespaces_by_category][:uncategorized][access_name] = 'true'
      @user.update(api_accessibility: access)
  
      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
      assert_select 'div#api-resources-list', {count: 1}
    end
  end

  test "should not show if user has other uncategorized access for the namespace" do
    ['delete_access_api_namespace_only', 'allow_exports', 'allow_duplication', 'allow_social_share_metadata', 'full_access_api_namespace_only', 'read_api_actions_only', 'full_access_for_api_actions_only', 'read_external_api_connections_only', 'full_access_for_external_api_connections_only', 'read_api_clients_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {}}}
      access[:api_namespaces][:namespaces_by_category][:uncategorized]= {}
      access[:api_namespaces][:namespaces_by_category][:uncategorized][access_name] = 'true'
      @user.update(api_accessibility: access)
  
      sign_in(@user)
      get api_namespace_url(@api_namespace)
      assert_response :success
      assert_select 'div#api-resources-list', {count: 0}
    end
  end

  # EDIT
  # API access for all_namespace
  test "should edit if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should edit if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should not edit if user has other access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "#edit: should show all categories when user has proper access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
    assert_select ".categories-form-partial", {count: 1 }, 'Shows checkboxes to assign categories' do
      # Allows all available categories as options
      Comfy::Cms::Category.of_type('ApiNamespace').each do |category|
        assert_select "label", {count: 1, text: category.label}
      end
    end
  end

  # API access by category
  test "should edit if user has category specific full_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should edit if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should not edit if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not edit if user has other category specific access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "#edit: should show categories when user has proper access for namespaces_by_category" do
    api_namespace_1 = comfy_cms_categories(:api_namespace_1)
    api_namespace_2 = comfy_cms_categories(:api_namespace_2)
    api_namespace_3 = comfy_cms_categories(:api_namespace_3)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{api_namespace_1.label}": {full_access: 'true'}, "#{api_namespace_2.label}": {full_access: 'true'}, uncategorized: {full_access: 'true'}}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
    assert_select ".categories-form-partial", {count: 1 }, 'Shows checkboxes to assign categories' do
      # Shows only the categories as option for which the user has access to.
      assert_select "label", {count: 1, text: api_namespace_1.label}
      assert_select "label", {count: 1, text: api_namespace_2.label}
      assert_select "label", {count: 0, text: api_namespace_3.label}
    end
  end

  # UPDATE
  # API access for all_namespace
  test "should update if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_redirected_to api_namespace_url(@api_namespace)
  end

  test "should update if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_redirected_to api_namespace_url(@api_namespace)
  end

  test "should not update if user has other access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should update if user has category specific full_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_redirected_to api_namespace_url(@api_namespace)
  end

  test "should update if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_redirected_to api_namespace_url(@api_namespace)
  end

  test "should not update if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not update if user has other category specific access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # DESTROY
  # API access for all_namespace
  test "should destroy if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should destroy if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should destroy if user has delete_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {delete_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should not destroy if user has other access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    assert_no_difference('ApiNamespace.count') do
      delete api_namespace_url(@api_namespace)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or delete_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should destroy if user has category specific full_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should destroy if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should destroy if user has category specific delete_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {delete_access_api_namespace_only: 'true'}}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should not destroy if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}}})

    sign_in(@user)
    assert_no_difference('ApiNamespace.count') do
      delete api_namespace_url(@api_namespace)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or delete_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not destroy if user has other category specific access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}}})

    sign_in(@user)
    assert_no_difference('ApiNamespace.count') do
      delete api_namespace_url(@api_namespace)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or delete_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # DISCARD_FAILED_API_ACTIONS
  # API access for all_namespace
  test "should discard_failed_api_actions if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

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

  test "should discard_failed_api_actions if user has full_access_for_api_actions_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_actions_only: 'true'}}})

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

  test "should not discard_failed_api_actions if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'discarded').size" do
        post discard_failed_api_actions_api_namespace_url(@api_namespace)
      end
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not discard_failed_api_actions if user has other access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_resources_only: 'true'}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'discarded').size" do
        post discard_failed_api_actions_api_namespace_url(@api_namespace)
      end
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should discard_failed_api_actions if user has category specific full_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

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

  test "should discard_failed_api_actions if user has category specific full_access_for_api_actions_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_api_actions_only: 'true'}}}})

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

  test "should not discard_failed_api_actions if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'discarded').size" do
        post discard_failed_api_actions_api_namespace_url(@api_namespace)
      end
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not discard_failed_api_actions if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'discarded').size" do
        post discard_failed_api_actions_api_namespace_url(@api_namespace)
      end
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not discard_failed_api_actions if user has other category specific access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'discarded').size" do
        post discard_failed_api_actions_api_namespace_url(@api_namespace)
      end
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # RERUN_FAILED_API_ACTIONS
  # API access for all_namespace
  test "should rerun_failed_api_actions if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size", -(failed_action_counts) do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
      assert_response :redirect
    end
  end

  test "should rerun_failed_api_actions if user has full_access_for_api_actions_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_actions_only: 'true'}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size", -(failed_action_counts) do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
      assert_response :redirect
    end
  end

  test "should not rerun_failed_api_actions if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not rerun_failed_api_actions if user has other access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_resources_only: 'true'}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should rerun_failed_api_actions if user has category specific full_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size", -(failed_action_counts) do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
      assert_response :redirect
    end
  end

  test "should rerun_failed_api_actions if user has category specific full_access_for_api_actions_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_for_api_actions_only: 'true'}}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size", -(failed_action_counts) do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
      assert_response :redirect
    end
  end

  test "should not rerun_failed_api_actions if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not rerun_failed_api_actions if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not rerun_failed_api_actions if user has other category specific access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_for_api_actions_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # EXPORT
  # API access for all_namespace
  test "should export if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\nanalytics_metadata,\npurge_resources_older_than,never\nassociations,[]\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should export if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\nanalytics_metadata,\npurge_resources_older_than,never\nassociations,[]\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should export if user has allow_exports for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {allow_exports: 'true'}}})

    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\nanalytics_metadata,\npurge_resources_older_than,never\nassociations,[]\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should not export if user has other access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_exports are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should export if user has category specific full_access for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\nanalytics_metadata,\npurge_resources_older_than,never\nassociations,[]\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should export if user has category specific full_access_api_namespace_only for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}}})

    sign_in(@user)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\nanalytics_metadata,\npurge_resources_older_than,never\nassociations,[]\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should export if user has category specific allow_exports for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}}})

    sign_in(@user)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\nanalytics_metadata,\npurge_resources_older_than,never\nassociations,[]\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should export if user has uncategorized access for the namespace with no category" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {allow_exports: 'true'}}}})

    sign_in(@user)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\nanalytics_metadata,\npurge_resources_older_than,never\nassociations,[]\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should not export if user has category specific other access for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}}})

    sign_in(@user)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_exports are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not export if user has other category specific access for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}}})

    sign_in(@user)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_exports are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # EXPORT_API_RESOURCES
  # API access for all_namespace
  test "should export_api_resources if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    resource_one = api_resources(:resource_with_all_types_one)
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,api_namespace_id,null,array,number,object,string,boolean,created_at,updated_at,user_id\n" \
    "#{resource_one.id},#{api_namespace.id},#{resource_one.properties['null']},#{resource_one.properties['array']},#{resource_one.properties['number']},\"{\"\"a\"\"=>\"\"apple\"\"}\",#{resource_one.properties['string']},\"\",#{resource_one.created_at},#{resource_one.updated_at},#{resource_one.user_id}\n" \
    "#{resource_two.id},#{api_namespace.id},#{resource_two.properties['null']},#{resource_two.properties['array']},#{resource_two.properties['number']},\"{\"\"b\"\"=>\"\"ball\"\"}\",#{resource_two.properties['string']},\"\",#{resource_two.created_at},#{resource_two.updated_at},#{resource_one.user_id}\n"

    assert_response :success
    assert_equal expected_csv, response.body
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_api_resources_#{DateTime.now.to_i}.csv"
  end

  test "should export_api_resources if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    resource_one = api_resources(:resource_with_all_types_one)
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,api_namespace_id,null,array,number,object,string,boolean,created_at,updated_at,user_id\n" \
    "#{resource_one.id},#{api_namespace.id},#{resource_one.properties['null']},#{resource_one.properties['array']},#{resource_one.properties['number']},\"{\"\"a\"\"=>\"\"apple\"\"}\",#{resource_one.properties['string']},\"\",#{resource_one.created_at},#{resource_one.updated_at},#{resource_one.user_id}\n" \
    "#{resource_two.id},#{api_namespace.id},#{resource_two.properties['null']},#{resource_two.properties['array']},#{resource_two.properties['number']},\"{\"\"b\"\"=>\"\"ball\"\"}\",#{resource_two.properties['string']},\"\",#{resource_two.created_at},#{resource_two.updated_at},#{resource_one.user_id}\n"

    assert_response :success
    assert_equal expected_csv, response.body
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_api_resources_#{DateTime.now.to_i}.csv"
  end

  test "should export_api_resources if user has allow_exports for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {allow_exports: 'true'}}})

    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    resource_one = api_resources(:resource_with_all_types_one)
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,api_namespace_id,null,array,number,object,string,boolean,created_at,updated_at,user_id\n" \
    "#{resource_one.id},#{api_namespace.id},#{resource_one.properties['null']},#{resource_one.properties['array']},#{resource_one.properties['number']},\"{\"\"a\"\"=>\"\"apple\"\"}\",#{resource_one.properties['string']},\"\",#{resource_one.created_at},#{resource_one.updated_at},#{resource_one.user_id}\n" \
    "#{resource_two.id},#{api_namespace.id},#{resource_two.properties['null']},#{resource_two.properties['array']},#{resource_two.properties['number']},\"{\"\"b\"\"=>\"\"ball\"\"}\",#{resource_two.properties['string']},\"\",#{resource_two.created_at},#{resource_two.updated_at},#{resource_one.user_id}\n"

    assert_response :success
    assert_equal expected_csv, response.body
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_api_resources_#{DateTime.now.to_i}.csv"
  end

  test "should not export_api_resources if user has other access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_resources_only: 'true'}}})

    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    resource_one = api_resources(:resource_with_all_types_one)
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_exports are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should export_api_resources if user has category specific full_access for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

    sign_in(@user)
    resource_one = api_resources(:resource_with_all_types_one)
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,api_namespace_id,null,array,number,object,string,boolean,created_at,updated_at,user_id\n" \
    "#{resource_one.id},#{api_namespace.id},#{resource_one.properties['null']},#{resource_one.properties['array']},#{resource_one.properties['number']},\"{\"\"a\"\"=>\"\"apple\"\"}\",#{resource_one.properties['string']},\"\",#{resource_one.created_at},#{resource_one.updated_at},#{resource_one.user_id}\n" \
    "#{resource_two.id},#{api_namespace.id},#{resource_two.properties['null']},#{resource_two.properties['array']},#{resource_two.properties['number']},\"{\"\"b\"\"=>\"\"ball\"\"}\",#{resource_two.properties['string']},\"\",#{resource_two.created_at},#{resource_two.updated_at},#{resource_one.user_id}\n"

    assert_response :success
    assert_equal expected_csv, response.body
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_api_resources_#{DateTime.now.to_i}.csv"
  end

  test "should export_api_resources if user has category specific full_access_api_namespace_only for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}}})

    sign_in(@user)
    resource_one = api_resources(:resource_with_all_types_one)
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,api_namespace_id,null,array,number,object,string,boolean,created_at,updated_at,user_id\n" \
    "#{resource_one.id},#{api_namespace.id},#{resource_one.properties['null']},#{resource_one.properties['array']},#{resource_one.properties['number']},\"{\"\"a\"\"=>\"\"apple\"\"}\",#{resource_one.properties['string']},\"\",#{resource_one.created_at},#{resource_one.updated_at},#{resource_one.user_id}\n" \
    "#{resource_two.id},#{api_namespace.id},#{resource_two.properties['null']},#{resource_two.properties['array']},#{resource_two.properties['number']},\"{\"\"b\"\"=>\"\"ball\"\"}\",#{resource_two.properties['string']},\"\",#{resource_two.created_at},#{resource_two.updated_at},#{resource_one.user_id}\n"

    assert_response :success
    assert_equal expected_csv, response.body
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_api_resources_#{DateTime.now.to_i}.csv"
  end

  test "should export_api_resources if user has category specific allow_exports for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}}})

    sign_in(@user)
    resource_one = api_resources(:resource_with_all_types_one)
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,api_namespace_id,null,array,number,object,string,boolean,created_at,updated_at,user_id\n" \
    "#{resource_one.id},#{api_namespace.id},#{resource_one.properties['null']},#{resource_one.properties['array']},#{resource_one.properties['number']},\"{\"\"a\"\"=>\"\"apple\"\"}\",#{resource_one.properties['string']},\"\",#{resource_one.created_at},#{resource_one.updated_at},#{resource_one.user_id}\n" \
    "#{resource_two.id},#{api_namespace.id},#{resource_two.properties['null']},#{resource_two.properties['array']},#{resource_two.properties['number']},\"{\"\"b\"\"=>\"\"ball\"\"}\",#{resource_two.properties['string']},\"\",#{resource_two.created_at},#{resource_two.updated_at},#{resource_one.user_id}\n"

    assert_response :success
    assert_equal expected_csv, response.body
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_api_resources_#{DateTime.now.to_i}.csv"
  end

  test "should export_api_resources if user has uncategorized access for the namespace with no category" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {allow_exports: 'true'}}}})

    sign_in(@user)
    resource_one = api_resources(:resource_with_all_types_one)
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,api_namespace_id,null,array,number,object,string,boolean,created_at,updated_at,user_id\n" \
    "#{resource_one.id},#{api_namespace.id},#{resource_one.properties['null']},#{resource_one.properties['array']},#{resource_one.properties['number']},\"{\"\"a\"\"=>\"\"apple\"\"}\",#{resource_one.properties['string']},\"\",#{resource_one.created_at},#{resource_one.updated_at},#{resource_one.user_id}\n" \
    "#{resource_two.id},#{api_namespace.id},#{resource_two.properties['null']},#{resource_two.properties['array']},#{resource_two.properties['number']},\"{\"\"b\"\"=>\"\"ball\"\"}\",#{resource_two.properties['string']},\"\",#{resource_two.created_at},#{resource_two.updated_at},#{resource_one.user_id}\n"

    assert_response :success
    assert_equal expected_csv, response.body
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_api_resources_#{DateTime.now.to_i}.csv"
  end

  test "should not export_api_resources if user has category specific other access for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}}})

    sign_in(@user)
    resource_one = api_resources(:resource_with_all_types_one)
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_exports are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not export_api_resources if user has other category specific access for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}}})

    sign_in(@user)
    resource_one = api_resources(:resource_with_all_types_one)
    resource_two = api_resources(:resource_with_all_types_two)

    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)

    get export_api_resources_api_namespace_url(api_namespace, format: :csv)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_exports are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # DUPLICATE_WITHOUT_ASSOCIATIONS
  # API access for all_namespace
  test "should duplicate_without_associations if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
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

  test "should duplicate_without_associations if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_api_namespace_only: 'true'}}})
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

  test "should duplicate_without_associations if user has allow_exports for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {allow_duplication: 'true'}}})
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

  test "should not duplicate_without_associations if user has other access for all_namespaces" do
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access_for_api_resources_only: 'true'}}})
    @api_namespace.api_form.destroy

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

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_duplication are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should duplicate_without_associations if user has category specific full_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}}})

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

  test "should duplicate_without_associations if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}}})

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

  test "should duplicate_without_associations if user has category specific allow_exports for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {allow_duplication: 'true'}}}})

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

  test "should duplicate_without_associations if user has uncategorized access for the namespace with no category" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {uncategorized: {allow_duplication: 'true'}}}})

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

  test "should not duplicate_without_associations if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}}})

    @api_namespace.api_form.destroy

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

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_duplication are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not duplicate_without_associations if user has other category specific access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {api_namespaces: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}}})

    @api_namespace.api_form.destroy

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

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_duplication are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # SOCIAL SHARE METADATA
  # API access for all_namespaces
  test 'social_share_metadata# should return success when the user has full_access/full_access_for_api_namespace_only/allow_social_share_metadata for all_namespaces' do
    ['full_access', 'full_access_api_namespace_only', 'allow_social_share_metadata'].each do |access_name|
      access = {api_namespaces: {all_namespaces: {}}}
      access[:api_namespaces][:all_namespaces][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"social_share_metadata"=>{"title"=>"Array", "description"=>"String", "image"=>"picto"}}}

      sign_in(@user)
      patch social_share_metadata_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'Social Share Metadata successfully updated.'
      assert_equal expected_message, flash[:success]
      assert_equal payload[:api_namespace]['social_share_metadata'], @api_namespace.reload.social_share_metadata
    end
  end

  test 'social_share_metadata# should deny when the user has other access like full_read_access/delete_access_api_namespace_only/allow_exports/allow_duplication/full_access_for_api_resources_only/full_access_for_api_actions_only/full_access_for_external_api_connections_only/full_access_for_api_clients_only/full_access_for_api_form_only for all_namespaces' do
    ['full_read_access', 'delete_access_api_namespace_only', 'allow_exports', 'allow_duplication', 'full_access_for_api_resources_only', 'full_access_for_api_actions_only', 'full_access_for_external_api_connections_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {all_namespaces: {}}}
      access[:api_namespaces][:all_namespaces][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"social_share_metadata"=>{"title"=>"Array", "description"=>"String", "image"=>"picto"}}}

      sign_in(@user)
      patch social_share_metadata_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_social_share_metadata are allowed to perform that action.'
      assert_equal expected_message, flash[:alert]
      refute_equal payload[:api_namespace]['social_share_metadata'], @api_namespace.reload.social_share_metadata
    end
  end

  # API access by category
  test 'social_share_metadata# should return success when the user has category-specific full_access/full_access_for_api_namespace_only/allow_social_share_metadata for a namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    ['full_access', 'full_access_api_namespace_only', 'allow_social_share_metadata'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {"#{category.label}": {}}}}
      access[:api_namespaces][:namespaces_by_category][:"#{category.label}"][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"social_share_metadata"=>{"title"=>"Array", "description"=>"String", "image"=>"picto"}}}

      sign_in(@user)
      patch social_share_metadata_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'Social Share Metadata successfully updated.'
      assert_equal expected_message, flash[:success]
      assert_equal payload[:api_namespace]['social_share_metadata'], @api_namespace.reload.social_share_metadata
    end
  end

  test 'social_share_metadata# should deny when the user has other category-specific access like full_read_access/delete_access_api_namespace_only/allow_exports/allow_duplication/full_access_for_api_resources_only/full_access_for_api_actions_only/full_access_for_external_api_connections_only/full_access_for_api_clients_only/full_access_for_api_form_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    ['full_read_access', 'delete_access_api_namespace_only', 'allow_exports', 'allow_duplication', 'full_access_for_api_resources_only', 'full_access_for_api_actions_only', 'full_access_for_external_api_connections_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {"#{category.label}": {}}}}
      access[:api_namespaces][:namespaces_by_category][:"#{category.label}"][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"social_share_metadata"=>{"title"=>"Array", "description"=>"String", "image"=>"picto"}}}

      sign_in(@user)
      patch social_share_metadata_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_social_share_metadata are allowed to perform that action.'
      assert_equal expected_message, flash[:alert]
      refute_equal payload[:api_namespace]['social_share_metadata'], @api_namespace.reload.social_share_metadata
    end
  end

  test 'social_share_metadata# should return success when the user has uncategorized full_access/full_access_for_api_namespace_only/allow_social_share_metadata for a namespace' do
    ['full_access', 'full_access_api_namespace_only', 'allow_social_share_metadata'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {uncategorized: {}}}}
      access[:api_namespaces][:namespaces_by_category][:uncategorized][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"social_share_metadata"=>{"title"=>"Array", "description"=>"String", "image"=>"picto"}}}

      sign_in(@user)
      patch social_share_metadata_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'Social Share Metadata successfully updated.'
      assert_equal expected_message, flash[:success]
      assert_equal payload[:api_namespace]['social_share_metadata'], @api_namespace.reload.social_share_metadata
    end
  end

  test 'social_share_metadata# should deny when the user has other uncategorized access like full_read_access/delete_access_api_namespace_only/allow_exports/allow_duplication/full_access_for_api_resources_only/full_access_for_api_actions_only/full_access_for_external_api_connections_only/full_access_for_api_clients_only/full_access_for_api_form_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    ['full_read_access', 'delete_access_api_namespace_only', 'allow_exports', 'allow_duplication', 'full_access_for_api_resources_only', 'full_access_for_api_actions_only', 'full_access_for_external_api_connections_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {uncategorized: {}}}}
      access[:api_namespaces][:namespaces_by_category][:uncategorized][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"social_share_metadata"=>{"title"=>"Array", "description"=>"String", "image"=>"picto"}}}

      sign_in(@user)
      patch social_share_metadata_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_social_share_metadata are allowed to perform that action.'
      assert_equal expected_message, flash[:alert]
      refute_equal payload[:api_namespace]['social_share_metadata'], @api_namespace.reload.social_share_metadata
    end
  end

  # API NAMESPACE SETTINGS
  # API access for all_namespaces
  test '#settings should return success when the user has full_access/full_access_for_api_namespace_only/allow_settings for all_namespaces' do
    ['full_access', 'full_access_api_namespace_only', 'allow_settings'].each do |access_name|
      access = {api_namespaces: {all_namespaces: {}}}
      access[:api_namespaces][:all_namespaces][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"purge_resources_older_than"=>"1.week"}}

      sign_in(@user)
      patch settings_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'Api namespace setting was successfully updated.'
      assert_equal expected_message, flash[:success]
      assert_equal payload[:api_namespace]['purge_resources_older_than'], @api_namespace.reload.purge_resources_older_than
    end
  end

  test '#settings should deny when the user has other access like full_read_access/delete_access_api_namespace_only/allow_exports/allow_duplication/full_access_for_api_resources_only/full_access_for_api_actions_only/full_access_for_external_api_connections_only/full_access_for_api_clients_only/full_access_for_api_form_only for all_namespaces' do
    ['full_read_access', 'delete_access_api_namespace_only', 'allow_exports', 'allow_duplication', 'full_access_for_api_resources_only', 'full_access_for_api_actions_only', 'full_access_for_external_api_connections_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {all_namespaces: {}}}
      access[:api_namespaces][:all_namespaces][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"purge_resources_older_than"=>"1.week"}}

      sign_in(@user)
      patch settings_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_settings are allowed to perform that action.'
      assert_equal expected_message, flash[:danger]
      refute_equal payload[:api_namespace]['purge_resources_older_than'], @api_namespace.reload.purge_resources_older_than
    end
  end

  # API access by category
  test '#settings should return success when the user has category-specific full_access/full_access_for_api_namespace_only/allow_settings for a namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    ['full_access', 'full_access_api_namespace_only', 'allow_settings'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {"#{category.label}": {}}}}
      access[:api_namespaces][:namespaces_by_category][:"#{category.label}"][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"purge_resources_older_than"=>"1.week"}}

      sign_in(@user)
      patch settings_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'Api namespace setting was successfully updated.'
      assert_equal expected_message, flash[:success]
      assert_equal payload[:api_namespace]['purge_resources_older_than'], @api_namespace.reload.purge_resources_older_than
    end
  end

  test '#settings should deny when the user has other category-specific access like full_read_access/delete_access_api_namespace_only/allow_exports/allow_duplication/full_access_for_api_resources_only/full_access_for_api_actions_only/full_access_for_external_api_connections_only/full_access_for_api_clients_only/full_access_for_api_form_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    ['full_read_access', 'delete_access_api_namespace_only', 'allow_exports', 'allow_duplication', 'full_access_for_api_resources_only', 'full_access_for_api_actions_only', 'full_access_for_external_api_connections_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {"#{category.label}": {}}}}
      access[:api_namespaces][:namespaces_by_category][:"#{category.label}"][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"purge_resources_older_than"=>"1.week"}}

      sign_in(@user)
      patch settings_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_settings are allowed to perform that action.'
      assert_equal expected_message, flash[:danger]
      refute_equal payload[:api_namespace]['purge_resources_older_than'], @api_namespace.reload.purge_resources_older_than
    end
  end

  test '#settings should return success when the user has uncategorized full_access/full_access_for_api_namespace_only/allow_settings for a namespace' do
    ['full_access', 'full_access_api_namespace_only', 'allow_settings'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {uncategorized: {}}}}
      access[:api_namespaces][:namespaces_by_category][:uncategorized][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"purge_resources_older_than"=>"1.week"}}

      sign_in(@user)
      patch settings_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'Api namespace setting was successfully updated.'
      assert_equal expected_message, flash[:success]
      assert_equal payload[:api_namespace]['purge_resources_older_than'], @api_namespace.reload.purge_resources_older_than
    end
  end

  test '#settings should deny when the user has other uncategorized access like full_read_access/delete_access_api_namespace_only/allow_exports/allow_duplication/full_access_for_api_resources_only/full_access_for_api_actions_only/full_access_for_external_api_connections_only/full_access_for_api_clients_only/full_access_for_api_form_only for the namespace' do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    ['full_read_access', 'delete_access_api_namespace_only', 'allow_exports', 'allow_duplication', 'full_access_for_api_resources_only', 'full_access_for_api_actions_only', 'full_access_for_external_api_connections_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'].each do |access_name|
      access = {api_namespaces: {namespaces_by_category: {uncategorized: {}}}}
      access[:api_namespaces][:namespaces_by_category][:uncategorized][access_name] = 'true'
      @user.update!(api_accessibility: access)

      payload = {api_namespace: {"purge_resources_older_than"=>"1.week"}}

      sign_in(@user)
      patch settings_api_namespace_url(@api_namespace), params: payload
      assert_response :redirect

      expected_message = 'You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_settings are allowed to perform that action.'
      assert_equal expected_message, flash[:danger]
      refute_equal payload[:api_namespace]['purge_resources_older_than'], @api_namespace.reload.purge_resources_older_than
    end
  end

  test '#settings: should run purge job on old api_resources' do
    @user.update!(api_accessibility: {api_namespaces: {all_namespaces: { 'allow_settings': 'true' }}})
    ApiResource.create(api_namespace: @api_namespace, created_at: 2.weeks.ago )
    payload = {api_namespace: {"purge_resources_older_than"=>"1.week"}}

    sign_in(@user)

    perform_enqueued_jobs do
      assert_difference '@api_namespace.reload.api_resources.count', -1 do
        patch settings_api_namespace_url(@api_namespace), params: payload
        Sidekiq::Worker.drain_all
      end
    end
  end

  test '#settings: should not run purge job on old api_resources if update is unsuccessful because of permission' do
    @user.update!(api_accessibility: {api_namespaces: {all_namespaces: { 'full_read_access': 'true' }}})
    ApiResource.create(api_namespace: @api_namespace, created_at: 2.weeks.ago )
    payload = {api_namespace: {"purge_resources_older_than"=>"1.week"}}

    sign_in(@user)

    perform_enqueued_jobs do
      assert_no_difference '@api_namespace.reload.api_resources.count'  do
        patch settings_api_namespace_url(@api_namespace), params: payload
        Sidekiq::Worker.drain_all
      end
    end

    expected_message = 'You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only or allow_settings are allowed to perform that action.'
    assert_equal expected_message, flash[:danger]

    refute_equal payload[:api_namespace]['purge_resources_older_than'], @api_namespace.reload.purge_resources_older_than
  end

  test '#settings: should not run purge job on old api_resources if update is unsuccessful' do
    @user.update!(api_accessibility: {api_namespaces: {all_namespaces: { 'allow_settings': 'true' }}})
    ApiResource.create(api_namespace: @api_namespace, created_at: 2.weeks.ago )
    payload = {api_namespace: {"purge_resources_older_than"=>"not_a_valid_value"}}

    sign_in(@user)

    perform_enqueued_jobs do
      assert_no_difference '@api_namespace.reload.api_resources.count'  do
        patch settings_api_namespace_url(@api_namespace), params: payload
        Sidekiq::Worker.drain_all
      end
    end

    assert_includes flash[:danger], 'Purge resources older than purge_resources_older_than is not valid'

    refute_equal payload[:api_namespace]['purge_resources_older_than'], @api_namespace.reload.purge_resources_older_than
  end

  ######## API Accessibility Tests - END #########

  # ANALYTICS METADATA
  test 'analytics_metadata# should return success when the user has authority to manage analytics' do
    @user.update!(can_manage_analytics: true)
    payload = {api_namespace: {"analytics_metadata"=>{"title"=>"Array", "author"=>"String", "thumbnail"=>"picto"}}}
    sign_in(@user)

    patch analytics_metadata_api_namespace_url(@api_namespace), params: payload
    assert_response :redirect

    expected_message = 'Analytics Metadata successfully updated.'
    assert_equal expected_message, flash[:success]
    assert_equal payload[:api_namespace]['analytics_metadata'], @api_namespace.reload.analytics_metadata
  end

  test 'analytics_metadata# should return error when the user has no authority to manage analytics' do
    @user.update!(can_manage_analytics: false)
    payload = {api_namespace: {"analytics_metadata"=>{"title"=>"Array", "author"=>"String", "thumbnail"=>"picto"}}}
    sign_in(@user)
    
    patch analytics_metadata_api_namespace_url(@api_namespace), params: payload
    assert_response :redirect

    expected_message = 'You do not have the permission to do that. Only users who can_manage_analytics are allowed to perform that action.'
    assert_equal expected_message, flash[:alert]
    refute_equal payload[:api_namespace]['analytics_metadata'], @api_namespace.reload.analytics_metadata
  end

  test "should create api_namespace with parent associations" do
    shops_namespace = ApiNamespace.create(name: 'shops', version: 1, properties: { name: '' })

    shops_namespace.api_resources.create(properties: {
      name: 'my shop'
    })

    sign_in(@user)
    assert_difference('ApiNamespace.count', 1) do
      post api_namespaces_url, params: { api_namespace: { name: 'products', properties: { title: '' }.to_json, associations: [{type: 'belongs_to', namespace: 'shops'}], version: 1 } }
    end
    products_namespace = ApiNamespace.last
    shops_namespace.reload

    shop_resource = shops_namespace.api_resources.first

    assert products_namespace.reload.properties.key?('shop_id')
    assert_includes products_namespace.associations, { "type" => 'belongs_to', "namespace" => 'shops' }
    assert_includes shops_namespace.associations, { "type" => 'has_many', "namespace" => 'products' }

    assert_difference('ApiResource.count') do
      post api_namespace_resources_url(api_namespace_id: products_namespace.id), params: { api_resource: { properties: { title: 'My product', shop_id: shop_resource.id }.to_json } }
    end

    assert_equal products_namespace.api_resources.pluck(:id), shop_resource.products.pluck(:id)

    assert_equal shop_resource, products_namespace.api_resources.first.shop
  end

  test "should create api_namespace with child associations" do
    products_namespace = ApiNamespace.create(name: 'products', version: 1, properties: { title: '' })

    products_namespace.api_resources.create(properties: {
      title: 'my product'
    })

    sign_in(@user)
    assert_difference('ApiNamespace.count', 1) do
      post api_namespaces_url, params: { api_namespace: { name: 'shops', properties: { name: '' }.to_json, associations: [{type: 'has_many', namespace: 'products'}], version: 1 } }
    end

    shops_namespace = ApiNamespace.last
    products_namespace.reload

    assert products_namespace.properties.key?('shop_id')
    assert_includes products_namespace.associations, { "type" => 'belongs_to', "namespace" => 'shops' }
    assert_includes shops_namespace.associations, { "type" => 'has_many', "namespace" => 'products' }

    assert_difference('ApiResource.count') do
      post api_namespace_resources_url(api_namespace_id: shops_namespace.id), params: { api_resource: { properties: { name: 'My shop'}.to_json } }
    end

    shop_resource = shops_namespace.api_resources.first

    assert_difference('ApiResource.count') do
      post api_namespace_resources_url(api_namespace_id: products_namespace.id), params: { api_resource: { properties: { title: 'My product', shop_id: shop_resource.id }.to_json } }
    end

    assert_equal [products_namespace.api_resources.last.id], shop_resource.products.pluck(:id)

    assert_equal shop_resource, products_namespace.api_resources.last.shop

    # already existing product resource 
    refute products_namespace.api_resources.first.shop
  end

  test "#update should add association" do
    shops_namespace = ApiNamespace.create(name: 'shops', version: 1, properties: { name: '' })
    products_namespace = ApiNamespace.create(name: 'products', version: 1, properties: { title: '' })

    shop = shops_namespace.api_resources.create(properties: {
      name: 'my shop'
    })

    products_namespace.api_resources.create(properties: {
      title: 'my product',
      shop_id: shop.id
    })

    # does not have dynamic methods defined without associations
    refute products_namespace.api_resources.first.reload.respond_to?(:shop)
    refute shops_namespace.api_resources.first.reload.respond_to?(:products)

    sign_in(@user)
    assert_changes('shops_namespace.reload.associations') do
      assert_changes('products_namespace.reload.associations') do
        assert_changes('products_namespace.reload.properties') do
          patch api_namespace_url(shops_namespace), params: { api_namespace: { associations: [{type: 'has_many', namespace: 'products'}], version: 1 } }
        end
      end
    end

    assert products_namespace.properties.key?('shop_id')
    assert_includes products_namespace.associations, { "type" => 'belongs_to', "namespace" => 'shops' }
    assert_includes shops_namespace.associations, { "type" => 'has_many', "namespace" => 'products' }

    products_namespace.reload
    shops_namespace.reload

    # should have dynamic methods defined
    assert products_namespace.api_resources.first.respond_to?(:shop)
    assert shops_namespace.api_resources.first.respond_to?(:products)
  end

  test "update association" do
    products_namespace = ApiNamespace.create(name: 'products', version: 1, properties: { title: '' })
    shops_namespace = ApiNamespace.create(name: 'shops', version: 1, properties: { name: '' }, associations: [{type: 'has_many', namespace: 'products'}])

    assert products_namespace.reload.properties.key?('shop_id')
    assert_includes products_namespace.associations, { "type" => 'belongs_to', "namespace" => 'shops' }
    assert_includes shops_namespace.reload.associations, { "type" => 'has_many', "namespace" => 'products' }

    shop = shops_namespace.api_resources.create(properties: {
      name: 'my shop'
    })

    products_namespace.api_resources.create(properties: {
      title: 'my product',
      shop_id: shop.id
    })

    # should have dynamic methods defined without associations
    assert products_namespace.api_resources.first.reload.respond_to?(:shop)
    assert shops_namespace.api_resources.first.reload.respond_to?(:products)

    sign_in(@user)
    assert_changes('shops_namespace.reload.associations') do
      assert_no_changes('products_namespace.reload.associations') do
        assert_no_changes('products_namespace.reload.properties') do
          patch api_namespace_url(shops_namespace), params: { api_namespace: { associations: [{type: 'has_one', namespace: 'products'}], version: 1 } }
        end
      end
    end

    refute_includes shops_namespace.reload.associations, { "type" => 'has_many', "namespace" => 'products' }

    assert_includes shops_namespace.reload.associations, { "type" => 'has_one', "namespace" => 'products' }

    assert products_namespace.reload.properties.key?('shop_id')
    assert_includes products_namespace.associations, { "type" => 'belongs_to', "namespace" => 'shops' }

    # should remove has_many dynamic method and add has_one methods
    assert products_namespace.api_resources.first.reload.respond_to?(:shop)
    refute shops_namespace.api_resources.first.reload.respond_to?(:products)
    assert shops_namespace.api_resources.first.reload.respond_to?(:product)
  end

  test "update api_namespace to remove associations" do
    shops_namespace = ApiNamespace.create(name: 'shops', version: 1, properties: { name: '' })
    products_namespace = ApiNamespace.create(name: 'products', version: 1, properties: { title: '' }, associations: [{type: 'belongs_to', namespace: 'shops'}])

    assert products_namespace.reload.properties.key?('shop_id')
    assert_includes products_namespace.associations, { "type" => 'belongs_to', "namespace" => 'shops' }
    assert_includes shops_namespace.reload.associations, { "type" => 'has_many', "namespace" => 'products' }

    shop = shops_namespace.api_resources.create(properties: {
      name: 'my shop'
    })

    products_namespace.api_resources.create(properties: {
      title: 'my product',
      shop_id: shop.id
    })

    # should have dynamic methods defined
    assert products_namespace.api_resources.first.reload.respond_to?(:shop)
    assert shops_namespace.api_resources.first.reload.respond_to?(:products)

    sign_in(@user)
    assert_changes('shops_namespace.reload.associations') do
      assert_no_changes('products_namespace.reload.associations') do
        assert_no_changes('products_namespace.reload.properties') do
          patch api_namespace_url(shops_namespace), params: { api_namespace: { associations: [], version: 1 } }
        end
      end
    end

    refute_includes shops_namespace.reload.associations, { "type" => 'has_many', "namespace" => 'products' }

    # removing foreign key and corresponding associations should be manual, we do not want to unintionally remove existing association
    assert products_namespace.reload.properties.key?('shop_id')
    assert_includes products_namespace.associations, { "type" => 'belongs_to', "namespace" => 'shops' }

    # should remove dynamic methods
    assert products_namespace.api_resources.first.reload.respond_to?(:shop)
    refute shops_namespace.api_resources.first.reload.respond_to?(:products)
  end
  
  test "should show link to associated resources" do
    owner_namespace = ApiNamespace.create(name: 'owners', version: 1, properties: {} )
    shops_namespace = ApiNamespace.create(name: 'shops', version: 1, properties: { name: ''}, associations: [{type: 'has_one', namespace: 'owners'}])
    products_namespace = ApiNamespace.create(name: 'products', version: 1, properties: { title: '' }, associations: [{type: 'belongs_to', namespace: 'shops'}])

    shop = shops_namespace.reload.api_resources.create(properties: {
      name: 'my shop'
    })

    owner = owner_namespace.reload.api_resources.create(properties: {
      name: 'owner',
      shop_id: shop.id
    })

    product = products_namespace.reload.api_resources.create(properties: {
      title: 'my product',
      shop_id: shop.id
    })

    sign_in(@user)
    get api_namespace_url(shops_namespace)
    
    # should include link to children resources namespace
    assert_select "tbody tr td a[href=?]", api_namespace_path(id: products_namespace.slug, q: {properties_cont: "\"shop_id\": #{shop.id}"}), { count: 1, text: 'products'}

    # should include link to children resource
    assert_select "tbody tr td a[href=?]", api_namespace_resource_path(api_namespace_id: owner_namespace.id, id: owner.id), { count: 1, text: owner.id.to_s}

    get api_namespace_url(products_namespace)
    # should include link to parent resource
    assert_select "tbody tr td a[href=?]", api_namespace_resource_path(api_namespace_id: shops_namespace.id, id: shop.id), { count: 1, text: shop.id.to_s}
  end
end
