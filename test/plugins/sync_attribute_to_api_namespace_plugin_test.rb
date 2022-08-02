require "test_helper"

class SyncAttributeToApiNamespacePluginTest < ActiveSupport::TestCase
  setup do
    @sync_attribute_to_api_namespace_plugin = external_api_clients(:sync_attribute_to_api_namespace_plugin)
    @api_namespace = @sync_attribute_to_api_namespace_plugin.api_namespace
    @api_form = @api_namespace.api_form
    Sidekiq::Testing.fake!
  end

  test "adds provided new attribute to api namespace and backfills the default value to its api-resources successfully" do
    metadata = {
      'ATTRIBUTE_NAME' => 'new_attribute',
      'DEFAULT_VALUE' => 'test_value',
    }
    @sync_attribute_to_api_namespace_plugin.update!(metadata: metadata)
    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    # Initially, the api_namespace and its api-resources does not have the new 'new_attribute'
    refute_includes @api_namespace.properties.keys, 'new_attribute'
    @api_namespace.api_resources.each do |resource|
      refute_includes resource.properties.keys, 'new_attribute'
    end

    perform_enqueued_jobs do
      assert_no_difference 'ApiNamespace.count' do
        assert_no_difference 'ApiResource.count' do
          @sync_attribute_to_api_namespace_plugin.run
          Sidekiq::Worker.drain_all
        end
      end
    end

    # The api-namespace and all api-resources are backfilled with provided 'DEFAULT_VALUE'
    assert_equal metadata['DEFAULT_VALUE'], @api_namespace.reload.properties['new_attribute']
    @api_namespace.reload.api_resources.each do |resource|
      assert_equal metadata['DEFAULT_VALUE'], resource.properties['new_attribute']
    end

    # The newly added attribute is non-renderable
    assert_equal '0', @api_form.reload.properties['new_attribute']['renderable']
  end

  test "adds provided new attribute to api namespace and backfills with empty string to its api-resources if DEFAULT_VALUE was not provided" do
    metadata = {
      'ATTRIBUTE_NAME' => 'new_attribute',
    }
    @sync_attribute_to_api_namespace_plugin.update!(metadata: metadata)
    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    # Initially, the api_namespace and its api-resources does not have the new 'new_attribute'
    refute_includes @api_namespace.properties.keys, 'new_attribute'
    @api_namespace.api_resources.each do |resource|
      refute_includes resource.properties.keys, 'new_attribute'
    end

    perform_enqueued_jobs do
      assert_no_difference 'ApiNamespace.count' do
        assert_no_difference 'ApiResource.count' do
          @sync_attribute_to_api_namespace_plugin.run
          Sidekiq::Worker.drain_all
        end
      end
    end

    # The api-namespace and all api-resources are backfilled with provided empty-string: ''
    assert_equal '', @api_namespace.reload.properties['new_attribute']
    @api_namespace.api_resources.reload.each do |resource|
      assert_equal '', resource.properties['new_attribute']
    end

    # The newly added attribute is non-renderable
    assert_equal '0', @api_form.reload.properties['new_attribute']['renderable']
  end

  test "adds provided new attribute to api namespace and backfills the default value to its api-resources only if that api-resource does not have the provided new-attribute" do
    metadata = {
      'ATTRIBUTE_NAME' => 'new_attribute',
      'DEFAULT_VALUE'=> 'test_value',
    }
    @sync_attribute_to_api_namespace_plugin.update!(metadata: metadata)
    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    # One of the api-resource already has the new-attribute
    new_attribute_existing_resource = @api_namespace.api_resources.last
    properties = new_attribute_existing_resource.properties.merge('new_attribute' => 'dummy_value')
    new_attribute_existing_resource.update!(properties: properties)

    # Initially, the api_namespace and its api-resources does not have the new 'new_attribute'
    refute_includes @api_namespace.properties.keys, 'new_attribute'
    @api_namespace.api_resources.where.not(id: new_attribute_existing_resource.id).each do |resource|
      refute_includes resource.properties.keys, 'new_attribute'
    end

    perform_enqueued_jobs do
      assert_no_difference 'ApiNamespace.count' do
        assert_no_difference 'ApiResource.count' do
          assert_no_changes -> { new_attribute_existing_resource.reload.properties['new_attribute'] } do
            @sync_attribute_to_api_namespace_plugin.run
            Sidekiq::Worker.drain_all
          end
        end
      end
    end

    # The api-namespace and all api-resources that do not have the new-attribute are backfilled
    assert_equal 'test_value', @api_namespace.reload.properties['new_attribute']
    @api_namespace.api_resources.reload.where.not(id: new_attribute_existing_resource.id).each do |resource|
      assert_equal 'test_value', resource.properties['new_attribute']
    end

    # Does not mutate the api-resource that already has the provided new-attribute
    assert_equal 'dummy_value', new_attribute_existing_resource.reload.properties['new_attribute']

    # The newly added attribute is non-renderable
    assert_equal '0', @api_form.reload.properties['new_attribute']['renderable']
  end

  test "returns error if the api_namespace already has the provided attribute" do
    metadata = {
      'ATTRIBUTE_NAME' => 'new_attribute',
      'DEFAULT_VALUE' => 'test_value',
    }
    @sync_attribute_to_api_namespace_plugin.update!(metadata: metadata)
    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    # @api_namespace already has the provided new-attribute
    new_properties = @api_namespace.properties.merge('new_attribute' => 'test 1')
    @api_namespace.update!(properties: new_properties)

    assert_includes @api_namespace.properties.keys, 'new_attribute'

    perform_enqueued_jobs do
      assert_no_difference 'ApiNamespace.count' do
        assert_no_difference 'ApiResource.count' do
          assert_no_changes -> { @api_namespace.reload.properties['new_attribute'] } do
            @sync_attribute_to_api_namespace_plugin.run
            Sidekiq::Worker.drain_all
          end
        end
      end
    end

    expected_message = 'The provided attribute is already defined in the ApiNamespace'
    assert_match expected_message, @sync_attribute_to_api_namespace_plugin.reload.error_message
  end

  test "returns error if the ATTRIBUTE_NAME is not provided" do
    metadata = {
      'DEFAULT_VALUE' => 'test_value',
    }
    @sync_attribute_to_api_namespace_plugin.update!(metadata: metadata)
    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    # @api_namespace already has the provided new-attribute
    new_properties = @api_namespace.properties.merge('new_attribute' => 'test 1')
    @api_namespace.update!(properties: new_properties)

    assert_includes @api_namespace.properties.keys, 'new_attribute'

    perform_enqueued_jobs do
      assert_no_difference 'ApiNamespace.count' do
        assert_no_difference 'ApiResource.count' do
          assert_no_changes -> { @api_namespace.reload.properties['new_attribute'] } do
            @sync_attribute_to_api_namespace_plugin.run
            Sidekiq::Worker.drain_all
          end
        end
      end
    end

    expected_message = 'ATTRIBUTE_NAME is missing!'
    assert_match expected_message, @sync_attribute_to_api_namespace_plugin.reload.error_message
  end

  test "adds provided new attribute to api namespace and backfills the default value: false(boolean) to its api-resources successfully" do
    metadata = {
      'ATTRIBUTE_NAME' => 'new_attribute',
      'DEFAULT_VALUE' => false,
    }
    @sync_attribute_to_api_namespace_plugin.update!(metadata: metadata)
    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    # Initially, the api_namespace and its api-resources does not have the new 'new_attribute'
    refute_includes @api_namespace.properties.keys, 'new_attribute'
    @api_namespace.api_resources.each do |resource|
      refute_includes resource.properties.keys, 'new_attribute'
    end

    perform_enqueued_jobs do
      assert_no_difference 'ApiNamespace.count' do
        assert_no_difference 'ApiResource.count' do
          @sync_attribute_to_api_namespace_plugin.run
          Sidekiq::Worker.drain_all
        end
      end
    end

    # The api-namespace and all api-resources are backfilled with provided 'DEFAULT_VALUE'
    assert_equal metadata['DEFAULT_VALUE'], @api_namespace.reload.properties['new_attribute']
    @api_namespace.reload.api_resources.each do |resource|
      assert_equal metadata['DEFAULT_VALUE'], resource.properties['new_attribute']
    end

    # The newly added attribute is non-renderable
    assert_equal '0', @api_form.reload.properties['new_attribute']['renderable']
  end
end
