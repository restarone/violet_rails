require "test_helper"

class ApiResourceTest < ActiveSupport::TestCase
  setup do
    Sidekiq::Testing.fake!
  end

  test "when initialized - inherits parent properties" do
    api_namespace = api_namespaces(:one)
    api_resource = ApiResource.new(api_namespace_id: api_namespace.id)

    assert_equal api_resource.properties, api_namespace.properties
  end

  test "when updated - adheres to presence validations enforced by API form" do
    api_namespace = api_namespaces(:one)
    api_form = api_forms(:one)
    api_form.update(properties: { 'name': {'label': 'name', 'placeholder': 'Name', 'field_type': 'input', 'required': '1' }})

    api_resource = ApiResource.create(api_namespace_id: api_namespace.id, properties: {'name': ''})
    refute api_resource.id

    assert_includes api_resource.errors.messages[:properties], 'name is required'
  end

  test "should set api_form's api_resource on initialization" do
    api_namespace = api_namespaces(:one)
    api_resource = ApiResource.new(api_namespace_id: api_namespace.id)

    assert_equal api_resource.api_namespace.api_form.api_resource, api_resource
  end
  
  test 'tracked_event' do
    api_resource = api_resources(:one)
    current_visit = ahoy_visits(:public)

    event = Ahoy::Event.create(
      name: "api-resource-create",
      visit_id: current_visit.id,
      properties: { api_resource_id: api_resource.id }
    )
    assert_equal api_resource.tracked_event, event
  end

  test 'tracked_user' do
    api_resource = api_resources(:one)
    user = users(:public)
    current_visit = ahoy_visits(:public)

    event = Ahoy::Event.create(
      name: "api-resource-create",
      visit_id: current_visit.id,
      properties: { api_resource_id: api_resource.id, user_id: user.id }
    )

    assert_equal api_resource.tracked_user, user
  end

  test "when created - model-level create-api-actions are fired" do
    api_namespace = api_namespaces(:one)
  
    redirect_api_action = api_actions(:create_api_action_one)
    send_email_api_action = api_actions(:create_api_action_two)

    custom_action = api_actions(:create_api_action_one).dup
    custom_action.action_type = "custom_action"
    custom_action.method_definition = "api_resource.as_json"
    custom_action.save!

    serve_action = api_actions(:create_api_action_one).dup
    serve_action.action_type = "serve_file"
    serve_action.save!

    send_web_request_action = api_actions(:create_api_action_one).dup
    send_web_request_action.action_type = "send_web_request"
    send_web_request_action.request_url = "http://www.example.com/success"
    send_web_request_action.http_method = "post"
    send_web_request_action.bearer_token = "TEST"
    send_web_request_action.payload_mapping = {"first_name": "test"}
    send_web_request_action.custom_headers = {"first_name": "test"}
    send_web_request_action.save!

    perform_enqueued_jobs do
      assert_difference 'ApiResource.count', +1 do
        assert_difference 'CreateApiAction.count', +api_namespace.reload.create_api_actions.count do
          @api_resource = ApiResource.create!(api_namespace_id: api_namespace.id, properties: {'name': 'John Doe'})
          # each model level api action should be executed individually
          assert_equal api_namespace.create_api_actions.where(action_type: ApiAction::EXECUTION_ORDER[:model_level]).count, FireApiActionsJob.jobs.count
          Sidekiq::Worker.drain_all
        end
      end
    end

    # The model level api-actions are fired through callback.
    @api_resource.reload.create_api_actions.where(action_type: ApiAction::EXECUTION_ORDER[:model_level]).each do |api_action|
      assert_equal 'complete', api_action.lifecycle_stage
    end

    # The controller level api-actions remain untouched.
    @api_resource.reload.create_api_actions.where(action_type: ApiAction::EXECUTION_ORDER[:controller_level]).each do |api_action|
      assert_equal 'initialized', api_action.lifecycle_stage
    end
  end

  test "when updated - model-level update-api-actions are fired" do
    api_namespace = api_namespaces(:one)
  
    redirect_api_action = api_actions(:create_api_action_one).dup
    redirect_api_action.assign_attributes(
      type: 'UpdateApiAction',
      action_type: 'redirect'
    )
    redirect_api_action.save!

    send_email_api_action = api_actions(:create_api_action_two)
    send_email_api_action.assign_attributes(
      type: 'UpdateApiAction',
      action_type: 'send_email'
    )
    send_email_api_action.save!

    custom_action = redirect_api_action.dup
    custom_action.action_type = "custom_action"
    custom_action.method_definition = "api_resource.as_json"
    custom_action.save!

    serve_action = redirect_api_action.dup
    serve_action.action_type = "serve_file"
    serve_action.save!

    send_web_request_action = redirect_api_action.dup
    send_web_request_action.action_type = "send_web_request"
    send_web_request_action.request_url = "http://www.example.com/success"
    send_web_request_action.http_method = "post"
    send_web_request_action.bearer_token = "TEST"
    send_web_request_action.payload_mapping = {"first_name": "test"}
    send_web_request_action.custom_headers = {"first_name": "test"}
    send_web_request_action.save!

    @api_resource = ApiResource.create!(api_namespace_id: api_namespace.id, properties: {'name': 'John Doe'})
    Sidekiq::Worker.drain_all
    perform_enqueued_jobs do
      assert_no_difference 'ApiResource.count' do
        assert_difference '@api_resource.reload.update_api_actions.count', +api_namespace.reload.update_api_actions.count do
          @api_resource.update!(properties: {'name': 'John Doe 2'})
          # each model level api action should be executed individually
          assert_equal api_namespace.reload.update_api_actions.where(action_type: ApiAction::EXECUTION_ORDER[:model_level]).count, FireApiActionsJob.jobs.count
          Sidekiq::Worker.drain_all
        end
      end
    end

    # The model level api-actions are fired through callback.
    @api_resource.reload.update_api_actions.where(action_type: ApiAction::EXECUTION_ORDER[:model_level]).each do |api_action|
      assert_equal 'complete', api_action.lifecycle_stage
    end

    # The controller level api-actions remain untouched.
    @api_resource.reload.update_api_actions.where(action_type: ApiAction::EXECUTION_ORDER[:controller_level]).each do |api_action|
      assert_equal 'initialized', api_action.lifecycle_stage
    end

    first_update_api_actions_batch = @api_resource.reload.update_api_actions.pluck(:id, :updated_at).to_h

    # Trigerring update-api-actions again
    perform_enqueued_jobs do
      assert_no_difference 'ApiResource.count' do
        assert_difference '@api_resource.reload.update_api_actions.count', +api_namespace.reload.update_api_actions.count do
          @api_resource.update!(properties: {'name': 'John Doe 1'})
          Sidekiq::Worker.drain_all
        end
      end
    end

    # Previous update-api-actions remain untouched
    first_update_api_actions_batch.each do |id, updated_at|
      assert_equal updated_at, ApiAction.find(id).updated_at
    end
  end

  test 'props' do
    api_namespace = api_namespaces(:one)
    api_resource = ApiResource.create!(api_namespace_id: api_namespace.id, properties: {'name': 'John Doe'})

    test_image = Rails.root.join("test/fixtures/files/fixture_image.png")
    file = Rack::Test::UploadedFile.new(test_image, "image/png")

    prop_1 = NonPrimitiveProperty.create!(label: "image", field_type: "file", attachment: file, api_resource_id: api_resource.id)
    prop_2 = NonPrimitiveProperty.create!(label: "text", field_type: "richtext", content: "<div>test</div>", api_resource_id: api_resource.id)

    # should be a hash containing both primitive and non-primitive properties
    assert_equal ['name', 'image', 'text'].sort, api_resource.props.keys.sort

    # should be able to access primitive properties
    assert_equal 'John Doe', api_resource.props['name']

    # should be able to access non-primitive properties through label
    # file type
    assert_equal prop_1.file_url, api_resource.props['image'].file_url
    # rich text
    assert_equal prop_2.content, api_resource.props['text'].content
  end

  test 'should define associations: has_many' do
    namespace_1 = ApiNamespace.create(name: 'items', version: 1, properties: { title: '' });
    namespace_2 = ApiNamespace.create(name: 'stall', version: 1, properties: { name: '' }, associations: [{type: 'has_many', namespace: 'items'}]);

    namespace_1.reload
    namespace_2.reload

    stall_1 = namespace_2.api_resources.create(properties: {name: 'Restarone'})
    stall_2 = namespace_2.api_resources.create(properties: {name: 'Engineering'})

    item_1 = namespace_1.api_resources.create(properties: {title: 'T-shirt', stall_id: stall_1.id})
    item_2 = namespace_1.api_resources.create(properties: {title: 'Jeans', stall_id: stall_1.id})

    assert_equal [item_1.id, item_2.id], stall_1.items.pluck(:id)
    assert_equal [], stall_2.items.pluck(:id)

    assert_equal stall_1, item_1.stall
    assert_equal stall_1, item_2.stall
  end

  test 'should define associations: has_one' do
    namespace_1 = ApiNamespace.create(name: 'items', version: 1, properties: { title: '' });
    namespace_2 = ApiNamespace.create(name: 'stall', version: 1, properties: { name: '' }, associations: [{type: 'has_one', namespace: 'items'}]);

    namespace_1.reload
    namespace_2.reload

    stall_1 = namespace_2.api_resources.create(properties: {name: 'Restarone'})
    stall_2 = namespace_2.api_resources.create(properties: {name: 'Engineering'})

    item_1 = namespace_1.api_resources.create(properties: {title: 'T-shirt', stall_id: stall_1.id})
    item_2 = namespace_1.api_resources.create(properties: {title: 'Jeans', stall_id: stall_1.id})

    assert_equal item_2, stall_1.item
    assert_equal nil, stall_2.item

    assert_equal stall_1, item_1.stall
  end

  test ' should destroy dependent associations when dependent is set to destroy' do
    namespace_1 = ApiNamespace.create(name: 'items', version: 1, properties: { title: '' });
    namespace_2 = ApiNamespace.create(name: 'stall', version: 1, properties: { name: '' }, associations: [{type: 'has_many', namespace: 'items', dependent: 'destroy'}]);

    namespace_1.reload
    namespace_2.reload

    stall_1 = namespace_2.api_resources.create(properties: {name: 'Restarone'})

    item_1 = namespace_1.api_resources.create(properties: {title: 'T-shirt', stall_id: stall_1.id})
    item_2 = namespace_1.api_resources.create(properties: {title: 'Jeans', stall_id: stall_1.id})

    assert_difference "namespace_2.reload.api_resources.count", -1 do
      assert_difference "namespace_1.reload.api_resources.count", -2 do
        stall_1.destroy
      end
    end
  end

  test 'should not allow destroy if dependent association exist when dependent is set to restrict_with_error' do
    namespace_1 = ApiNamespace.create(name: 'items', version: 1, properties: { title: '' });
    namespace_2 = ApiNamespace.create(name: 'stall', version: 1, properties: { name: '' }, associations: [{type: 'has_one', namespace: 'items', dependent: 'restrict_with_error'}]);

    namespace_1.reload
    namespace_2.reload

    stall_1 = namespace_2.api_resources.create(properties: {name: 'Restarone'})

    item_1 = namespace_1.api_resources.create(properties: {title: 'T-shirt', stall_id: stall_1.id})

    assert_no_difference "namespace_2.reload.api_resources.count"  do
      assert_no_difference "namespace_1.reload.api_resources.count"  do
        stall_1.destroy
      end
    end

    assert_equal ["Cannot delete record because dependent items exist"], stall_1.reload.errors.full_messages
  end

  test 'should not remove dependent association when dependent is not set' do
    namespace_1 = ApiNamespace.create(name: 'items', version: 1, properties: { title: '' });
    namespace_2 = ApiNamespace.create(name: 'stall', version: 1, properties: { name: '' }, associations: [{type: 'has_many', namespace: 'items'}]);

    namespace_1.reload
    namespace_2.reload

    stall_1 = namespace_2.api_resources.create(properties: {name: 'Restarone'})

    item_1 = namespace_1.api_resources.create(properties: {title: 'T-shirt', stall_id: stall_1.id})

    assert_difference "namespace_2.reload.api_resources.count", -1  do
      assert_no_difference "namespace_1.reload.api_resources.count"  do
        stall_1.destroy
      end
    end
  end
end
