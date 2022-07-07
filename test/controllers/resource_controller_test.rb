require "test_helper"

class ResourceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_namespace = api_namespaces(:one)
  end

  test 'should allow #create' do
    payload = {
      data: {
          properties: {
            first_name: 'Don',
            last_name: 'Restarone'
          }
      }
    }

    assert_difference "@api_namespace.api_resources.count", +1 do
      actions_count = @api_namespace.create_api_actions.size
      assert_difference "@api_namespace.executed_api_actions.count", actions_count do
        assert_difference "ApiActionMailer.deliveries.size", +1 do
          perform_enqueued_jobs do
            post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id, params: payload)
            assert_response :redirect
          end
        end
      end
    end
  end

  test 'should allow #create with non primitive properties' do
    test_image = Rails.root.join("test/fixtures/files/fixture_image.png")
    file = Rack::Test::UploadedFile.new(test_image, "image/png")
    payload = {
      data: {
          properties: {
            first_name: 'Don',
            last_name: 'Restarone'
          },
          non_primitive_properties_attributes: [
             {
              label: "image", 
              field_type: "file",
              attachment: file,
            },
            {
              label: "image", 
              field_type: "richtext",
              content: "<div>test</div>"
            }
          ]
      }
    }
    assert_difference "@api_namespace.api_resources.count", +1 do
      assert_difference "NonPrimitiveProperty.count", +2 do
        assert_difference "ActiveStorage::Attachment.count", +1 do
          post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id), params: payload
          assert_response :redirect
        end
      end
    end
  end

  test 'should allow #create when recaptcha is enabled and recaptcha is verified' do
    @api_namespace.api_form.update(show_recaptcha: true)
    payload = {
      data: {
          properties: {
            first_name: 'Don',
            last_name: 'Restarone'
          }
      }
    }
    assert_difference "@api_namespace.api_resources.count", +1 do
      post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id), params: payload
      assert_response :redirect
    end
  end

  test 'should not allow #create when recaptcha is enabled and recaptcha verification failed' do
    @api_namespace.api_form.update(show_recaptcha: true)
    payload = {
      data: {
          properties: {
            first_name: 'Don',
            last_name: 'Restarone'
          }
      }
    }
    # Recaptcha is disabled for test env by deafult
    Recaptcha.configuration.skip_verify_env.delete("test")
    assert_difference "@api_namespace.api_resources.count", +0 do
      post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id), params: payload
      assert_response :redirect
    end

    Recaptcha.configuration.skip_verify_env.push("test")
  end

  test 'should allow #create when recaptcha-v3 is enabled and recaptcha is verified' do
    @api_namespace.api_form.update(show_recaptcha_v3: true)
    payload = {
      data: {
          properties: {
            first_name: 'Don',
            last_name: 'Restarone'
          }
      }
    }
    assert_difference "@api_namespace.api_resources.count", +1 do
      post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id), params: payload
      assert_response :redirect
    end
  end

  test 'should not allow #create when recaptcha-v3 is enabled and recaptcha verification failed' do
    @api_namespace.api_form.update(show_recaptcha_v3: true)
    payload = {
      data: {
          properties: {
            first_name: 'Don',
            last_name: 'Restarone'
          }
      }
    }
    # Recaptcha is disabled for test env by deafult
    Recaptcha.configuration.skip_verify_env.delete("test")
    assert_difference "@api_namespace.api_resources.count", +0 do
      post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id), params: payload
      assert_response :redirect
      assert_match "reCAPTCHA verification failed, please try again.", flash[:error]
    end

    Recaptcha.configuration.skip_verify_env.push("test")
  end

  test 'should not allow #create if required properties is missing' do
    @api_namespace.api_form.update(properties: { 'name': {'label': 'Test', 'placeholder': 'Test', 'field_type': 'input', 'required': '1' }})
    payload = {
      data: {
          properties: {
            name: '',
          }
      }
    }
    assert_no_difference "@api_namespace.api_resources.count" do
      post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id), params: payload
    end
  end

  test 'should allow #create when input type is radio button with single select' do
    api_namespace = api_namespaces(:array_namespace)
    payload = {
      data: {
          properties: {
            name: 'Yes',
          }
      }
    }
    assert_difference "api_namespace.api_resources.count", +1 do
      post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
    end
  end

  test 'should allow #create when input type is radio button with multi select' do
    api_namespace = api_namespaces(:array_namespace)
    api_namespace.api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Test', 'input_type': 'radio', 'select_type': 'single' }})
    payload = {
      data: {
          properties: {
            name: ['Yes', 'No'],
          }
      }
    }
    assert_difference "api_namespace.api_resources.count", +1 do
      post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
    end
  end

  test 'should allow #create when input type is tel' do
    api_namespace = api_namespaces(:one)
    api_namespace.api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Test', 'type_validation': 'tel'}})
    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }
    assert_difference "api_namespace.api_resources.count", +1 do
      post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
    end
  end

  test 'should allow #create and redirect to evaluated redirect_url if redirect_type is dynamic_url' do
    payload = {
      data: {
          properties: {
            flag: false
          }
      }
    }

    redirect_action = @api_namespace.create_api_actions.find_by(action_type: 'redirect')
    redirect_action.update!(redirect_type: 'dynamic_url', redirect_url: "\#{ api_resource.properties['flag'] == 'true' ? dashboard_path : api_namespaces_path }")

    assert_difference "@api_namespace.api_resources.count", +1 do
      actions_count = @api_namespace.create_api_actions.size
      assert_difference "@api_namespace.executed_api_actions.count", actions_count do
        post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id, params: payload)
        assert_response :redirect
        assert_redirected_to api_namespaces_path
      end
    end
  end

  test 'should allow #create and should not redirect by evaluating redirect_url if redirect_type is not dynamic_url' do
    payload = {
      data: {
          properties: {
            flag: false
          }
      }
    }

    redirect_action = @api_namespace.create_api_actions.find_by(action_type: 'redirect')
    url = "\#{ api_resource.properties['flag'] == 'true' ? dashboard_path : api_namespaces_path }"
    redirect_action.update!(redirect_type: 'cms_page', redirect_url: url)

    assert_difference "@api_namespace.api_resources.count", +1 do
      actions_count = @api_namespace.create_api_actions.size
      assert_difference "@api_namespace.executed_api_actions.count", actions_count do
        post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id, params: payload)
        assert_response :redirect
        assert_redirected_to url
      end
    end
  end
end
