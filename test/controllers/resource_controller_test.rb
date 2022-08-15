require "test_helper"

class ResourceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_namespace = api_namespaces(:one)
    Sidekiq::Testing.inline!
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
            assert_response :success
            Sidekiq::Worker.drain_all
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
          assert_response :success
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
      assert_response :success
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
      assert_response :success
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
      assert_response :success
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

    ResourceController.any_instance.stubs(:verify_recaptcha).returns(false) do
      ResourceController.any_instance.stubs(:recaptcha_reply).returns({success: 'false', score: 0.1}) do
        assert_difference "@api_namespace.api_resources.count", +0 do
          post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id), params: payload
          assert_response :success
    
          assert_match "reCAPTCHA verification failed, please try again.", response.parsed_body
        end
      end
    end
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

    perform_enqueued_jobs do
      assert_difference "@api_namespace.api_resources.count", +1 do
        post api_namespace_resource_index_url(api_namespace_id: @api_namespace.id), params: payload
        Sidekiq::Worker.drain_all
      end
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

    assert_response :success
    assert_equal "window.location.replace('#{api_namespaces_path}')", response.parsed_body
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

    assert_response :success
    assert_equal "window.location.replace('#{url}')", response.parsed_body
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

    assert_response :success
    assert_equal "window.location.replace('#{cms_page.full_path}')", response.parsed_body 
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

  test 'success_message: should support erb syntax' do
    api_namespace = api_namespaces(:one)
    api_namespace.api_form.update(success_message: "<div class=\"custom-class\">test success message <%= api_namespace.id %></div>")

    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }
    post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload

    assert_response :success
    assert_equal "<div class=\"custom-class\">test success message #{api_namespace.id}</div>", flash[:notice]
  end

  test 'success_message: should support string interpolation syntax' do
    api_namespace = api_namespaces(:one)
    api_namespace.api_form.update(success_message: "<div class=\"custom-class\">test success message \#{api_namespace.id}</div>")

    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }

    post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload

    assert_response :success
    assert_equal "<div class=\"custom-class\">test success message #{api_namespace.id}</div>", flash[:notice]
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

    assert_match 'test failure message', response.parsed_body
    refute_equal 301, response.status
    assert_response :success


    refute_match 'window.location.replace', response.parsed_body
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

    assert_match 'test failure message', response.parsed_body
    refute flash[:notice]
  end

  test 'should show default toast if failure message does not contain html tags' do
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

    assert_match 'test failure message', response.parsed_body

    # only default toasts have these class names 
    assert_match 'alert-danger', response.parsed_body
  end

  test 'should not contain default toast class name if failure message contains html tags' do
    api_namespace = api_namespaces(:one)
    api_namespace.api_form.update(failure_message: '<div class="custom-class">test failure message</div>', properties: { 'name': {'label': 'name', 'placeholder': 'Name', 'field_type': 'input', 'required': '1' } })

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

    assert_response :success
    assert_match 'custom-class', response.parsed_body
    assert_match 'test failure message', response.parsed_body

    # only default toasts have these class names 
    refute_match 'alert-danger', response.parsed_body
    refute_match 'alert-success', response.parsed_body
  end

  test 'should support erb syntax' do
    api_namespace = api_namespaces(:one)
    api_namespace.api_form.update(failure_message: "<div class=\"custom-class\">test failure message <%= api_namespace.id %></div>", properties: { 'name': {'label': 'name', 'placeholder': 'Name', 'field_type': 'input', 'required': '1' } })

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

    assert_response :success
    assert_match "<div class=\\\"custom-class\\\">test failure message #{api_namespace.id}<\\/div>", response.parsed_body
  end

  test 'should not assume erb syntax as html tag' do
    api_namespace = api_namespaces(:one)
    api_namespace.api_form.update(failure_message: "test failure message <%= api_namespace.id %>", properties: { 'name': {'label': 'name', 'placeholder': 'Name', 'field_type': 'input', 'required': '1' } })

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

    assert_response :success
    # only default toasts have these class names 
    assert_match 'alert-danger', response.parsed_body
    assert_match "test failure message #{api_namespace.id}", response.parsed_body
  end

  test 'should support string interpolation syntax' do
    api_namespace = api_namespaces(:one)
    api_namespace.api_form.update(failure_message: "<div class=\"custom-class\">test failure message \#{api_namespace.id}</div>", properties: { 'name': {'label': 'name', 'placeholder': 'Name', 'field_type': 'input', 'required': '1' } })

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

    assert_response :success
    assert_match "<div class=\\\"custom-class\\\">test failure message #{api_namespace.id}<\\/div>", response.parsed_body
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
        assert_response :success
      end
    end

    assert_equal @controller.view_assigns['api_resource'].id, @controller.view_assigns['redirect_action'].api_resource_id
    refute @controller.view_assigns['redirect_action'].api_namespace_id
  end

  test 'should allow #create and the custom action should be executed' do
    api_namespace = api_namespaces(:three)
    api_namespace.api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Test', 'type_validation': 'tel'}})
    api_action = api_actions(:create_custom_api_action_three)
    api_action.update!(method_definition: "User.create!(email: 'contact1@restarone.com', password: '123456', password_confirmation: '123456')")

    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }

    perform_enqueued_jobs do
      assert_difference "api_namespace.api_resources.count", +1 do
        # Custom Action creates a new user
        assert_difference "User.count", +1 do
          post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
          Sidekiq::Worker.drain_all
        end
      end
    end
  end

  test 'should allow #create and the custom action should be executed in the order that is defined' do
    api_namespace = api_namespaces(:three)
    api_namespace.api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Test', 'type_validation': 'tel'}})
    api_action = api_actions(:create_custom_api_action_three)
    api_action.update!(position: 0, method_definition: "User.create!(email: 'custom_action_0@restarone.com', password: '123456', password_confirmation: '123456')")

    2.times.each do |n|
      new_custom_action = api_actions(:create_custom_api_action_three).dup
      new_custom_action.method_definition = "User.create!(email: 'custom_action_#{ n + 1 }@restarone.com', password: '123456', password_confirmation: '123456')"
      new_custom_action.position = n + 1
      new_custom_action.save!
    end

    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }

    perform_enqueued_jobs do
      assert_difference "api_namespace.api_resources.count", +1 do
        # Total 3 Custom Action. Each creates a new user
        assert_difference "User.count", +3 do
          post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
          Sidekiq::Worker.drain_all
        end
      end
    end

    api_resource = @controller.view_assigns['api_resource']
    # The different triggered actions should be completed
    api_resource.reload.create_api_actions.each do |action|
      assert_equal 'complete', action.lifecycle_stage
    end

    # According to the order of custom_api_actions, the users should be created in the order: 1) custom_action_0@restarone.com   2) custom_action_1@restarone.com  3) custom_action_2@restarone.com
    assert User.find_by_email('custom_action_1@restarone.com').created_at > User.find_by_email('custom_action_0@restarone.com').created_at
    assert User.find_by_email('custom_action_1@restarone.com').created_at < User.find_by_email('custom_action_2@restarone.com').created_at
  end

  test 'should allow #create and the custom actions (sending emails) should be executed in the order that is defined' do
    api_namespace = api_namespaces(:three)
    api_namespace.api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Test', 'type_validation': 'tel'}})
    api_action = api_actions(:create_custom_api_action_three)
    api_action.update!(position: 0, method_definition: "User.invite!({email: 'custom_action_0@restarone.com'}, current_user)")

    2.times.each do |n|
      new_custom_action = api_actions(:create_custom_api_action_three).dup
      new_custom_action.method_definition = "User.invite!({email: 'custom_action_#{ n + 1 }@restarone.com'}, current_user)"
      new_custom_action.position = n + 1
      new_custom_action.save!
    end

    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }

    perform_enqueued_jobs do
      assert_difference "api_namespace.api_resources.count", +1 do
        # Total 3 Custom Action. Each sends an email.
        assert_difference "ActionMailer::Base.deliveries.count", +3 do
          post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
          Sidekiq::Worker.drain_all
        end
      end
    end

    api_resource = @controller.view_assigns['api_resource']
    # The different triggered actions should be completed
    api_resource.reload.create_api_actions.each do |action|
      assert_equal 'complete', action.lifecycle_stage
    end

    # According to the order of custom_api_actions, the emails should be sent to email-addresses in the order: 1) custom_action_0@restarone.com   2) custom_action_1@restarone.com  3) custom_action_2@restarone.com
    3.times.each do |n|
      assert_includes ActionMailer::Base.deliveries[n].to, "custom_action_#{ n }@restarone.com"
    end
  end

  test 'should allow #create and the custom actions (controller context code) should be executed in the order that is defined and save its output as lifecycle_message' do
    api_namespace = api_namespaces(:three)
    api_namespace.api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Test', 'type_validation': 'tel'}})

    api_action = api_actions(:create_custom_api_action_three)
    api_action.update!(position: 0, method_definition: "api_namespace.as_json")

    new_custom_action = api_actions(:create_custom_api_action_three).dup
    new_custom_action.method_definition = "api_resource.as_json"
    new_custom_action.position = 1
    new_custom_action.save!

    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }
    perform_enqueued_jobs do
      assert_difference "api_namespace.api_resources.count", +1 do
        post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
        Sidekiq::Worker.drain_all
      end
    end

    api_namespace = @controller.view_assigns['api_namespace']
    api_resource = @controller.view_assigns['api_resource']

    # The different triggered actions should be completed
    api_resource.reload.create_api_actions.each do |action|
      assert_equal 'complete', action.lifecycle_stage
    end

    assert_equal api_namespace.as_json.to_json, api_resource.create_api_actions.first.lifecycle_message
    assert_equal api_resource.as_json.to_json, api_resource.create_api_actions.second.lifecycle_message
  end

  test 'should allow #create and the custom actions (sending emails) should be executed in the order that is defined with other api_actions' do
    api_namespace = api_namespaces(:three)
    api_namespace.api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Test', 'type_validation': 'tel'}})
    api_action = api_actions(:create_custom_api_action_three)
    api_action.update!(position: 0, method_definition: "User.invite!({email: 'custom_action_0@restarone.com'}, current_user)")

    2.times.each do |n|
      new_custom_action = api_actions(:create_custom_api_action_three).dup
      new_custom_action.method_definition = "User.invite!({email: 'custom_action_#{ n + 1 }@restarone.com'}, current_user)"
      new_custom_action.position = n + 1
      new_custom_action.save!
    end

    send_email_action = api_actions(:create_custom_api_action_three).dup
    send_email_action.action_type = "send_email"
    send_email_action.email = "custom_action_3@restarone.com"
    send_email_action.position = 3
    send_email_action.save!

    redirect_action = api_actions(:create_custom_api_action_three).dup
    redirect_action.action_type = "redirect"
    redirect_action.redirect_url = "/"
    redirect_action.position = 4
    redirect_action.save!

    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }

    perform_enqueued_jobs do
      assert_difference "api_namespace.api_resources.count", +1 do
        # Total 3 Custom Action & 1 Send-Email Action. Each sends an email.
        assert_difference "ActionMailer::Base.deliveries.count", +4 do
          post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
          Sidekiq::Worker.drain_all
        end
      end
    end

    assert_equal "window.location.replace('#{redirect_action.redirect_url}')", response.parsed_body

    api_resource = @controller.view_assigns['api_resource']
    # The different triggered actions should be completed
    api_resource.reload.create_api_actions.each do |action|
      assert_equal 'complete', action.lifecycle_stage
    end

    # At first, email is sent to 'custom_action_3@restarone.com' through send_email_action
    assert_includes ActionMailer::Base.deliveries.first.to, "custom_action_3@restarone.com"

    # According to the order of custom_api_actions, the emails should be sent to email-addresses in the order: 1) custom_action_0@restarone.com   2) custom_action_1@restarone.com  3) custom_action_2@restarone.com
    # At the end, email is sent to 'custom_action_3@restarone.com' through send_email_action
    3.times.each do |n|
      assert_includes ActionMailer::Base.deliveries[n + 1].to, "custom_action_#{ n }@restarone.com"
    end
  end

  test 'should allow #create and the api_actions should be executed in the defined order in ApiAction.EXECUTION_ORDER' do
    api_namespace = api_namespaces(:three)
    api_namespace.api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Test', 'type_validation': 'tel'}})
    custom_api_action_1 = api_actions(:create_custom_api_action_three)
    custom_api_action_1.update!(position: 5, method_definition: "User.invite!({email: 'custom_action_0@restarone.com'}, current_user)")

    custom_custom_action_2 = api_actions(:create_custom_api_action_three).dup
    custom_custom_action_2.method_definition = "User.invite!({email: 'custom_action_1@restarone.com'}, current_user)"
    custom_custom_action_2.position = 4
    custom_custom_action_2.save!

    send_email_action = api_actions(:create_custom_api_action_three).dup
    send_email_action.action_type = "send_email"
    send_email_action.email = "custom_action_3@restarone.com"
    send_email_action.position = 1
    send_email_action.save!

    redirect_action = api_actions(:create_custom_api_action_three).dup
    redirect_action.action_type = "redirect"
    redirect_action.redirect_url = "/"
    redirect_action.position = 2
    redirect_action.save!

    send_web_request_action = api_actions(:create_api_action_three).dup
    send_web_request_action.api_namespace_id = api_namespace.id
    send_web_request_action.api_resource_id = nil
    send_web_request_action.position = 3
    send_web_request_action.save!

    site = Comfy::Cms::Site.first
    file = site.files.create(
      label:        "test",
      description:  "test file",
      file:         fixture_file_upload("fixture_image.png", "image/jpeg")
    )

    serve_file_action = api_actions(:create_custom_api_action_three).dup
    serve_file_action.action_type = "serve_file"
    serve_file_action.file_snippet = "{{ cms:file_link #{file.id} }}"
    serve_file_action.position = 2
    serve_file_action.save!

    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }

    perform_enqueued_jobs do
      assert_difference "api_namespace.api_resources.count", +1 do
        # Total 2 Custom Action & 1 Send-Email Action. Each sends an email.
        assert_difference "ActionMailer::Base.deliveries.count", +3 do
          post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
          Sidekiq::Worker.drain_all
        end
      end
    end

    assert_equal "window.location.replace('#{redirect_action.redirect_url}')", response.parsed_body

    api_resource = @controller.view_assigns['api_resource']

    # Different type of ApiActions are executed in the defined order
    # First, model level actions are executed and after that, the controller level actions
    assert_equal ApiAction::EXECUTION_ORDER[:model_level] + ApiAction::EXECUTION_ORDER[:controller_level], api_resource.create_api_actions.reorder(nil).order(updated_at: :asc).pluck(:action_type).uniq

    # Custom Api Action are executed according to their position
    custom_actions = api_resource.reload.create_api_actions.where(action_type: 'custom_action').reorder(nil)
    assert_equal custom_actions.order(updated_at: :asc).pluck(:id), custom_actions.order(position: :asc).pluck(:id)
  end

  test 'should redirect back if no redirect action is defined' do
    api_namespace = api_namespaces(:no_api_actions)
    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }

    assert_difference "ApiResource.all.size", +1 do
      assert_no_difference "ApiAction.all.size" do
        post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
      end
    end
  
    assert_response :success
    assert_equal "location.reload()", response.parsed_body
  end
  
  test 'tracking diabled: should not track current vist and current user after create' do
    Subdomain.current.update(tracking_enabled: false)
    api_namespace = api_namespaces(:one)
    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }
    assert_no_difference "Ahoy::Event.count" do
      post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
    end
  end

  test 'tracking enabled: should track current vist and current user after create' do
    user = users(:public)
    Subdomain.current.update(tracking_enabled: true)
    api_namespace = api_namespaces(:one)
    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }
    assert_difference "Ahoy::Event.count", +1 do
      post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
    end
    assert_equal Ahoy::Event.last.properties['api_resource_id'], ApiResource.last.id
    assert_equal Ahoy::Event.last.properties['api_namespace_id'], api_namespace.id
    assert_equal Ahoy::Event.last.name, 'api-resource-create'
    # When user is not signed in
    refute Ahoy::Event.last.properties['user_id']

    sign_in(user)
    assert_difference "Ahoy::Event.count", +1 do
      post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
    end
    assert_equal Ahoy::Event.last.properties['api_resource_id'], ApiResource.last.id 
    assert_equal Ahoy::Event.last.properties['api_namespace_id'], api_namespace.id
    assert_equal Ahoy::Event.last.name, 'api-resource-create'
    # When user is signed in
    assert_equal Ahoy::Event.last.properties['user_id'], user.id 
  end
end
