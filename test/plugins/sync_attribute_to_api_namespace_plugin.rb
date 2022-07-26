require "test_helper"

class SyncAttributeToApiNamespacePluginTest < ActiveSupport::TestCase
  setup do
    @sync_attribute_to_api_namespace_plugin = external_api_clients(:sync_attribute_to_api_namespace_plugin)
    @api_namespace = @sync_attribute_to_api_namespace_plugin.api_namespace
    Sidekiq::Testing.fake!
  end

  test "adds provided new attribute to api namespace and backfills the default value to its api-resources successfully" do
    metadata = {
      'attribute_name' => 'test_attribute',
      'default_value' => 'test_value',
      'placeholder_value' => 'Enter you new_attribute value here.',
    }
    @sync_attribute_to_api_namespace_plugin.update!(metadata: metadata)
    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    # Initially, the api_namespace and its api-resources does not have the new 'test_attribute'
    refute_includes @api_namespace.properties.keys, 'test_attribute'
    @api_namespace.api_resources.each do |resource|
      refute_includes resource.properties.keys, 'test_attribute'
    end

    perform_enqueued_jobs do
      assert_no_difference 'ApiNamespace.count' do
        assert_no_difference 'ApiResource.count' do
          @sync_attribute_to_api_namespace_plugin.run
          Sidekiq::Worker.drain_all
        end
      end
    end

    assert_equal metadata['placeholder_value'], @api_namespace.reload.properties['test_attribute']
    # All api-resources are backfilled with provided 'default_value'
    @api_namespace.reload.api_resources.each do |resource|
      assert_equal metadata['default_value'], resource.properties['test_attribute']
    end
  end

  test "adds provided new attribute to api namespace and backfills with empty string to its api-resources if default_value was not provided" do
    metadata = {
      'attribute_name' => 'test_attribute',
      'placeholder_value' => 'Enter you new_attribute value here.',
    }
    @sync_attribute_to_api_namespace_plugin.update!(metadata: metadata)
    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    # Initially, the api_namespace and its api-resources does not have the new 'test_attribute'
    refute_includes @api_namespace.properties.keys, 'test_attribute'
    @api_namespace.api_resources.each do |resource|
      refute_includes resource.properties.keys, 'test_attribute'
    end

    perform_enqueued_jobs do
      assert_no_difference 'ApiNamespace.count' do
        assert_no_difference 'ApiResource.count' do
          @sync_attribute_to_api_namespace_plugin.run
          Sidekiq::Worker.drain_all
        end
      end
    end

    assert_equal metadata['placeholder_value'], @api_namespace.reload.properties['test_attribute']
    # All api-resources are backfilled with provided empty-string: ''
    @api_namespace.api_resources.reload.each do |resource|
      assert_equal '', resource.properties['test_attribute']
    end
  end

  test "adds provided new attribute to api namespace and backfills the default value to its api-resources for array data" do
    metadata = {
      'attribute_name' => 'test_attribute',
      'default_value' => 'one',
      'placeholder_value' => ['one', 'two'],
    }
    @sync_attribute_to_api_namespace_plugin.update!(metadata: metadata)
    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    # Initially, the api_namespace and its api-resources does not have the new 'test_attribute'
    refute_includes @api_namespace.properties.keys, 'test_attribute'
    @api_namespace.api_resources.each do |resource|
      refute_includes resource.properties.keys, 'test_attribute'
    end

    perform_enqueued_jobs do
      assert_no_difference 'ApiNamespace.count' do
        assert_no_difference 'ApiResource.count' do
          @sync_attribute_to_api_namespace_plugin.run
          Sidekiq::Worker.drain_all
        end
      end
    end

    assert_equal metadata['placeholder_value'], @api_namespace.reload.properties['test_attribute']
    # All api-resources are backfilled with provided empty-string: ''
    @api_namespace.api_resources.reload.each do |resource|
      assert_equal 'one', resource.properties['test_attribute']
    end
  end

  test "adds provided new attribute to api namespace and backfills the default value to its api-resources only if that api-resource does not have the provided new-attribute" do
    metadata = {
      'attribute_name' => 'test_attribute',
      'default_value'=> 'test_value',
      'placeholder_value' => 'Enter you new_attribute value here.',
    }
    @sync_attribute_to_api_namespace_plugin.update!(metadata: metadata)
    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    # One of the api-resource already has the new-attribute
    new_attribute_existing_resource = @api_namespace.api_resources.last
    properties = new_attribute_existing_resource.properties.merge('test_attribute' => 'dummy_value')
    new_attribute_existing_resource.update!(properties: properties)

    # Initially, the api_namespace and its api-resources does not have the new 'test_attribute'
    refute_includes @api_namespace.properties.keys, 'test_attribute'
    @api_namespace.api_resources.where.not(id: new_attribute_existing_resource.id).each do |resource|
      refute_includes resource.properties.keys, 'test_attribute'
    end

    perform_enqueued_jobs do
      assert_no_difference 'ApiNamespace.count' do
        assert_no_difference 'ApiResource.count' do
          assert_no_changes -> { new_attribute_existing_resource.reload.properties['test_attribute'] } do
            @sync_attribute_to_api_namespace_plugin.run
            Sidekiq::Worker.drain_all
          end
        end
      end
    end

    assert_equal metadata['placeholder_value'], @api_namespace.reload.properties['test_attribute']
    # All api-resources that do not have the new-attribute are backfilled
    @api_namespace.api_resources.reload.where.not(id: new_attribute_existing_resource.id).each do |resource|
      assert_equal 'test_value', resource.properties['test_attribute']
    end

    # Does not mutate the api-resource that already has the provided new-attribute
    assert_equal 'dummy_value', new_attribute_existing_resource.reload.properties[metadata['attribute_name']]
  end

  test "returns error if the api_namespace already has the provided attribute" do
    metadata = {
      'attribute_name' => 'test_attribute',
      'default_value' => 'test_value',
      'placeholder_value' => 'Enter you new_attribute value here.',
    }
    @sync_attribute_to_api_namespace_plugin.update!(metadata: metadata)
    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    # @api_namespace already has the provided new-attribute
    new_properties = @api_namespace.properties.merge('test_attribute' => 'test 1')
    @api_namespace.update!(properties: new_properties)

    assert_includes @api_namespace.properties.keys, 'test_attribute'

    perform_enqueued_jobs do
      assert_no_difference 'ApiNamespace.count' do
        assert_no_difference 'ApiResource.count' do
          assert_no_changes -> { @api_namespace.reload.properties['test_attribute'] } do
            @sync_attribute_to_api_namespace_plugin.run
            Sidekiq::Worker.drain_all
          end
        end
      end
    end

    expected_message = 'The provided attribute is already defined in the ApiNamespace'
    assert_match expected_message, @sync_attribute_to_api_namespace_plugin.reload.error_message
  end
end
