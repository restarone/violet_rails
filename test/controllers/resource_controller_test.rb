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

  test 'should allow #create and the custom action should be executed' do
    api_namespace = api_namespaces(:three)
    api_namespace.api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Test', 'type_validation': 'tel'}})
    api_action = api_actions(:create_custom_api_action_three)
    api_action.update!(method_definition: "User.create!(email: 'contact1@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)")

    payload = {
      data: {
          properties: {
            name: 123,
          }
      }
    }
    assert_difference "api_namespace.api_resources.count", +1 do
      # Custom Action creates a new user
      assert_difference "User.count", +1 do
        post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
      end
    end
  end

  test 'should allow #create and the custom action should be executed in the order that is defined' do
    api_namespace = api_namespaces(:three)
    api_namespace.api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Test', 'type_validation': 'tel'}})
    api_action = api_actions(:create_custom_api_action_three)
    api_action.update!(position: 0, method_definition: "User.create!(email: 'custom_action_0@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)")

    2.times.each do |n|
      new_custom_action = api_actions(:create_custom_api_action_three).dup
      new_custom_action.method_definition = "User.create!(email: 'custom_action_#{ n + 1 }@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)"
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
    assert_difference "api_namespace.api_resources.count", +1 do
      # Total 3 Custom Action. Each creates a new user
      assert_difference "User.count", +3 do
        post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
      end
    end

    api_resource = @controller.view_assigns['api_resource']
    # The different triggered actions should be completed
    api_resource.create_api_actions.each do |action|
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
    assert_difference "api_namespace.api_resources.count", +1 do
      # Total 3 Custom Action. Each sends an email.
      assert_difference "ActionMailer::Base.deliveries.count", +3 do
        post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
      end
    end

    api_resource = @controller.view_assigns['api_resource']
    # The different triggered actions should be completed
    api_resource.create_api_actions.each do |action|
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
    assert_difference "api_namespace.api_resources.count", +1 do
      post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
    end

    api_namespace = @controller.view_assigns['api_namespace']
    api_resource = @controller.view_assigns['api_resource']

    # The different triggered actions should be completed
    api_resource.create_api_actions.each do |action|
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
    assert_difference "api_namespace.api_resources.count", +1 do
      # Total 3 Custom Action & 1 Send-Email Action. Each sends an email.
      assert_difference "ActionMailer::Base.deliveries.count", +4 do
        post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
      end
    end

    assert_redirected_to redirect_action.redirect_url

    api_resource = @controller.view_assigns['api_resource']
    # The different triggered actions should be completed
    api_resource.create_api_actions.each do |action|
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
    custom_api_action_1.update!(position: 0, method_definition: "User.invite!({email: 'custom_action_0@restarone.com'}, current_user)")

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
    assert_difference "api_namespace.api_resources.count", +1 do
      # Total 2 Custom Action & 1 Send-Email Action. Each sends an email.
      assert_difference "ActionMailer::Base.deliveries.count", +3 do
        post api_namespace_resource_index_url(api_namespace_id: api_namespace.id), params: payload
      end
    end

    assert_redirected_to redirect_action.redirect_url

    api_resource = @controller.view_assigns['api_resource']

    # Different type of ApiActions are executed in the defined order
    assert_equal ApiAction::EXECUTION_ORDER, api_resource.create_api_actions.reorder(nil).order(updated_at: :asc).pluck(:action_type).uniq

    # Custom Api Action are executed according to their position
    custom_actions = api_resource.create_api_actions.where(action_type: 'custom_action').reorder(nil)
    assert_equal custom_actions.order(updated_at: :asc).pluck(:id), custom_actions.order(position: :asc).pluck(:id)
  end
end
