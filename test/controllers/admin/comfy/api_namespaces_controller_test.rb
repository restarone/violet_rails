require "test_helper"

class Comfy::Admin::ApiNamespacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})
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
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,#{api_namespace.social_share_metadata}\n"
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

    @user.update(api_accessibility: {})
    sign_in(@user)
    assert_no_difference('ApiNamespace.count') do
      assert_no_difference('ApiResource.count') do
        assert_no_difference('ApiAction.count') do
          assert_no_difference('ApiClient.count') do
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

  # INDEX
  # API access for all_namespaces
  test "should get index if user has full_access for all namespaces" do
    sign_in(@user)
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has full_read_access for all namespaces" do
    sign_in(@user)
    @user.update(api_accessibility: {all_namespaces: {full_read_access: 'true'}})
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has full_access_api_namespace_only for all namespaces" do
    sign_in(@user)
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has other access for all namespaces" do
    sign_in(@user)
    @user.update(api_accessibility: {all_namespaces: {allow_exports: 'true'}})
    get api_namespaces_url
    assert_response :success
  end

  # API access by category
  test "should get index if user has category specific full_access for one of the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has category specific full_read_access for one of the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}})

    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has category specific full_access_api_namespace_only for one of the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  test "should get index if user has category specific other access for one of the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}})

    sign_in(@user)
    get api_namespaces_url
    assert_response :success
  end

  # NEW
  # API access for all_namespace
  test "should get new if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    get new_api_namespace_url
    assert_response :success
  end

  test "should get new if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})

    sign_in(@user)
    get new_api_namespace_url
    assert_response :success
  end

  test "should not get new if user has other access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_read_access: 'true'}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    get new_api_namespace_url
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only for all_namespaces are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # CREATE
  # API access for all_namespace
  test "should create if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    assert_difference('ApiNamespace.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
    api_namespace = ApiNamespace.last
    assert api_namespace.slug
    assert_redirected_to api_namespace_url(api_namespace)
  end

  test "should create if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})

    sign_in(@user)
    assert_difference('ApiNamespace.count') do
      post api_namespaces_url, params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    end
    api_namespace = ApiNamespace.last
    assert api_namespace.slug
    assert_redirected_to api_namespace_url(api_namespace)
  end

  test "should not create if user has other access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_read_access: 'true'}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

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

  # IMPORT_AS_JSON
  # API access for all_namespace
  test "should import_as_json if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

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
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})

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
    @user.update(api_accessibility: {all_namespaces: {full_read_access: 'true'}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

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

  # SHOW
  # API access for all_namespace
  test "should show if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has full_read_access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_read_access: 'true'}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should not show if user has other access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or delete_access_api_namespace_only or allow_exports or allow_duplication or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should show if user has category specific full_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has category specific full_read_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has uncategorized access for the namespace with no category" do
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {full_read_access: 'true'}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should show if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should not show if user has other category specific access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}})

    sign_in(@user)
    get api_namespace_url(@api_namespace)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_read_access or delete_access_api_namespace_only or allow_exports or allow_duplication or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # EDIT
  # API access for all_namespace
  test "should edit if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should edit if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should not edit if user has other access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should edit if user has category specific full_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should edit if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :success
  end

  test "should not edit if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}})

    sign_in(@user)
    get edit_api_namespace_url(@api_namespace)
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # UPDATE
  # API access for all_namespace
  test "should update if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_redirected_to api_namespace_url(@api_namespace)
  end

  test "should update if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_redirected_to api_namespace_url(@api_namespace)
  end

  test "should not update if user has other access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_redirected_to api_namespace_url(@api_namespace)
  end

  test "should update if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_redirected_to api_namespace_url(@api_namespace)
  end

  test "should not update if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}})

    sign_in(@user)
    patch api_namespace_url(@api_namespace), params: { api_namespace: { name: @api_namespace.name, namespace_type: @api_namespace.namespace_type, properties: @api_namespace.properties.to_json, requires_authentication: @api_namespace.requires_authentication, version: @api_namespace.version } }
    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # DESTROY
  # API access for all_namespace
  test "should destroy if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should destroy if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should destroy if user has delete_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {delete_access_api_namespace_only: 'true'}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should not destroy if user has other access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should destroy if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should destroy if user has category specific delete_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {delete_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    assert_difference('ApiNamespace.count', -1) do
      delete api_namespace_url(@api_namespace)
    end

    assert_redirected_to api_namespaces_url
  end

  test "should not destroy if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}})

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
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

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

  test "should discard_failed_api_actions if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})

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

  test "should not discard_failed_api_actions if user has other access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

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

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should discard_failed_api_actions if user has category specific full_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

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

  test "should discard_failed_api_actions if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}})

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

  test "should not discard_failed_api_actions if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}})

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

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not discard_failed_api_actions if user has other category specific access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}})

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

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # RERUN_FAILED_API_ACTIONS
  # API access for all_namespace
  test "should rerun_failed_api_actions if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size", -(failed_action_counts) do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
      assert_response :redirect
    end
  end

  test "should rerun_failed_api_actions if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size", -(failed_action_counts) do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
      assert_response :redirect
    end
  end

  test "should not rerun_failed_api_actions if user has other access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # API access by category
  test "should rerun_failed_api_actions if user has category specific full_access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size", -(failed_action_counts) do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
      assert_response :redirect
    end
  end

  test "should rerun_failed_api_actions if user has category specific full_access_api_namespace_only for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size", -(failed_action_counts) do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
      assert_response :redirect
    end
  end

  test "should not rerun_failed_api_actions if user has category specific other access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  test "should not rerun_failed_api_actions if user has other category specific access for the namespace" do
    category = comfy_cms_categories(:api_namespace_1)
    @api_namespace.update(category_ids: [category.id])

    category_2 = comfy_cms_categories(:api_namespace_2)
    @user.update(api_accessibility: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}})

    failed_action = api_actions(:two)
    failed_action.update(lifecycle_stage: 'failed')
    failed_action_counts = @api_namespace.executed_api_actions.where(lifecycle_stage: 'failed').size

    sign_in(@user)
    assert_no_difference "@api_namespace.reload.executed_api_actions.where(lifecycle_stage: 'failed').size" do
      post rerun_failed_api_actions_api_namespace_url(@api_namespace)
    end

    assert_response :redirect

    expected_message = "You do not have the permission to do that. Only users with full_access or full_access_api_namespace_only are allowed to perform that action."
    assert_equal expected_message, flash[:alert]
  end

  # EXPORT
  # API access for all_namespace
  test "should export if user has full_access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should export if user has full_access_api_namespace_only for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})

    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should export if user has allow_exports for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {allow_exports: 'true'}})

    sign_in(@user)
    api_namespace = api_namespaces(:namespace_with_all_types)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should not export if user has other access for all_namespaces" do
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

    sign_in(@user)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should export if user has category specific full_access_api_namespace_only for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}})

    sign_in(@user)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should export if user has category specific allow_exports for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}})

    sign_in(@user)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should export if user has uncategorized access for the namespace with no category" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {allow_exports: 'true'}}})

    sign_in(@user)
    stubbed_date = DateTime.new(2022, 1, 1)
    DateTime.stubs(:now).returns(stubbed_date)
    get export_api_namespace_url(api_namespace, format: :csv)
    expected_csv = "id,#{api_namespace.id}\nname,namespace_with_all_types\nslug,namespace_with_all_types\nversion,1\nnull,\narray,\"[\"\"yes\"\", \"\"no\"\"]\"\nnumber,123\nobject,\"{\"\"a\"\"=>\"\"b\"\", \"\"c\"\"=>\"\"d\"\"}\"\nstring,string\nboolean,true\nrequires_authentication,false\nnamespace_type,create-read-update-delete\ncreated_at,#{api_namespace.created_at}\nupdated_at,#{api_namespace.updated_at}\nsocial_share_metadata,\n"
    assert_response :success
    assert_equal response.body, expected_csv
    assert_equal response.header['Content-Disposition'], "attachment; filename=api_namespace_#{api_namespace.id}_#{DateTime.now.to_i}.csv"
  end

  test "should not export if user has category specific other access for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}})

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
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})

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
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})

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
    @user.update(api_accessibility: {all_namespaces: {allow_exports: 'true'}})

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
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})

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

  # API access by category
  test "should export_api_resources if user has category specific full_access for the namespace" do
    api_namespace = api_namespaces(:namespace_with_all_types)
    category = comfy_cms_categories(:api_namespace_1)
    api_namespace.update(category_ids: [category.id])
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_exports: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {allow_exports: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}})

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
    @user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})
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
    @user.update(api_accessibility: {all_namespaces: {full_access_api_namespace_only: 'true'}})
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
    @user.update(api_accessibility: {all_namespaces: {allow_duplication: 'true'}})
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
    @user.update(api_accessibility: {all_namespaces: {full_access_for_api_resources_only: 'true'}})
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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_access_api_namespace_only: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {allow_duplication: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {uncategorized: {allow_duplication: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category.label}": {full_read_access: 'true'}}})

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
    @user.update(api_accessibility: {namespaces_by_category: {"#{category_2.label}": {full_access: 'true'}}})

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
end
