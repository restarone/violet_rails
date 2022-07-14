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

  test 'should allow #create with the current_user & current_visit being available in the send_web_request action' do
    @api_namespace.api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Test', 'type_validation': 'tel'}})

    api_action = api_actions(:one)
    api_action.update!(
                      type: 'CreateApiAction',
                      bearer_token: 'test-token',
                      position: 0,
                      action_type: 'send_web_request',
                      request_url: "http://www.example.com/success",
                      payload_mapping: {"email": '#{current_user.email}'},
                      custom_headers: {"User-Id": '#{current_visit.user_id}'},
                      http_method: 'post'
                    )
    @api_namespace.api_actions.where.not(id: api_action.id).destroy_all
    user = users(:public)
    sign_in(user)

    stub_post = stub_request(:post, "http://www.example.com/success").with(headers: { 'User-Id' => user.id.to_s }, body: {'email' => user.email}).to_return(:body => "abc")

    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }

    assert_difference "@api_namespace.api_resources.count", +1 do
      post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id), params: payload
    end

    # Provided current_user & current_visit variable are available through send_web_request api-action
    assert_requested stub_post
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
      end
    end

    assert_response :redirect
    assert_redirected_to api_namespaces_path
    # The evaluated value is saved as lifecycle_message
    assert_equal api_namespaces_path, @controller.view_assigns['redirect_action'].lifecycle_message
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
      end
    end

    assert_response :redirect
    assert_redirected_to url
    # The evaluated value is not saved as lifecycle_message
    assert_equal url, @controller.view_assigns['redirect_action'].lifecycle_message
  end

  test 'should allow #create and should redirect to the provided cms-page if redirect_type is cms_page' do
    payload = {
      data: {
          properties: {
            flag: false
          }
      }
    }
    site = Comfy::Cms::Site.first
    layout = site.layouts.create!(label: 'default', identifier: 'default')
    cms_page = site.pages.first.children.create!(label: 'thank-you', slug: 'thank-you', full_path: '/thank-you', site_id: site.id, layout_id: layout.id)

    redirect_action = @api_namespace.create_api_actions.find_by(action_type: 'redirect')
    redirect_action.update!(redirect_type: 'cms_page', redirect_url: cms_page.full_path)

    assert_difference "@api_namespace.api_resources.count", +1 do
      actions_count = @api_namespace.create_api_actions.size
      assert_difference "@api_namespace.executed_api_actions.count", actions_count do
        post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id, params: payload)
      end
    end

    assert_response :redirect
    assert_redirected_to cms_page.full_path
    assert_equal cms_page.full_path, @controller.view_assigns['redirect_action'].lifecycle_message
  end

  test 'should allow #create and show the custom success message' do
    api_namespace = api_namespaces(:one)
    api_namespace.api_form.update(success_message: 'test success message')
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

    assert_equal 'test success message', flash[:notice]
    refute flash[:error]
  end

  test 'should allow #create and show the custom success message even if no redirect action is defined' do
    api_namespace = api_namespaces(:one)
    api_namespace.api_form.update(success_message: 'test success message')
    api_namespace.api_actions.where(type: 'CreateApiAction', action_type: 'redirect').destroy_all

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

    assert_equal 'test success message', flash[:notice]
    refute flash[:error]
  end

  test 'should deny #create and show the custom failure message' do
    api_namespace = api_namespaces(:one)
    api_namespace.api_form.update(failure_message: 'test failure message', properties: { 'name': {'label': 'name', 'placeholder': 'Name', 'field_type': 'input', 'required': '1' } })
    payload = {
      data: {
          properties: {
            name: '',
          }
      }
    }
    assert_no_difference "api_namespace.api_resources.count" do
      post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
    end

    assert_equal 'test failure message', flash[:error]
    refute flash[:notice]
  end

  test 'should deny #create and show the custom failure message even if no redirect action is defined' do
    api_namespace = api_namespaces(:one)
    api_namespace.api_form.update(failure_message: 'test failure message', properties: { 'name': {'label': 'name', 'placeholder': 'Name', 'field_type': 'input', 'required': '1' } })
    api_namespace.api_actions.where(type: 'CreateApiAction', action_type: 'redirect').destroy_all

    payload = {
      data: {
          properties: {
            name: '',
          }
      }
    }
    assert_no_difference "api_namespace.api_resources.count" do
      post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
    end

    assert_equal 'test failure message', flash[:error]
    refute flash[:notice]
  end

  test 'should allow #create and the api_actions should be fetched of the api_resource instead of api_namespace' do
    payload = {
      data: {
          properties: {
            flag: false
          }
      }
    }

    actions_count = @api_namespace.create_api_actions.size
    assert_difference "@api_namespace.api_resources.count", +1 do
      assert_difference "@api_namespace.executed_api_actions.count", actions_count do
        post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id, params: payload)
        assert_response :redirect
      end
    end

    assert_equal @controller.view_assigns['api_resource'].id, @controller.view_assigns['redirect_action'].api_resource_id
    refute @controller.view_assigns['redirect_action'].api_namespace_id
  end
end
