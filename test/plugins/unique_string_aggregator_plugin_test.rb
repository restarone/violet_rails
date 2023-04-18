require "test_helper"

class UniqueStringAggregatorPluginTest < ActiveSupport::TestCase
    setup do
        @unique_string_aggregator_plugin = external_api_clients(:unique_string_aggregator_plugin)
        @api_namespace = @unique_string_aggregator_plugin.api_namespace
        @output_api_namespace = api_namespaces(:unique_string_aggregator_output_tags)
        Sidekiq::Testing.fake!
    end

    # How test fixtures are set up:
    # By default, PRISTINE is set to true in the plugin metadata
    # By default, the plugin is connected to unique_string_aggregator_target API namespace
    # By default, the output API namespace is unique_string_aggregator_output_tags and it has input property

    test "Should raise an error if the output API namespace slug and the current API namespace slug are the same" do
        metadata = @unique_string_aggregator_plugin.metadata
        metadata["OUTPUT_API_NAMESPACE"] = @api_namespace.slug
        @unique_string_aggregator_plugin.update(metadata: metadata)

        perform_enqueued_jobs do
            @unique_string_aggregator_plugin.run
            Sidekiq::Worker.drain_all
        end

        expected_error_message = "API Namespace resource pollution detected. OUTPUT_API_NAMESPACE slug and the slug of the current API namespace cannot be the same."
        assert_equal expected_error_message, @unique_string_aggregator_plugin.reload.error_message
    end

    test "Should raise an error if the provided input property does not exist on the current API namespace" do
        metadata = @unique_string_aggregator_plugin.metadata
        metadata["INPUT_PROPERTY"] = "non-existent property"
        @unique_string_aggregator_plugin.update(metadata: metadata)

        perform_enqueued_jobs do
            @unique_string_aggregator_plugin.run
            Sidekiq::Worker.drain_all
        end

        expected_error_message = "Input property does not exist on the current API namespace"
        assert_equal expected_error_message, @unique_string_aggregator_plugin.reload.error_message
    end

    test "Should raise an error if an API namespace with the provided output API namespace slug does not exist" do
        metadata = @unique_string_aggregator_plugin.metadata
        metadata["OUTPUT_API_NAMESPACE"] = "non-existent API namespace"
        @unique_string_aggregator_plugin.update(metadata: metadata)

        perform_enqueued_jobs do
            @unique_string_aggregator_plugin.run
            Sidekiq::Worker.drain_all
        end

        expected_error_message = "An API namespace with the provided output API namespace slug does not exist"
        assert_equal expected_error_message, @unique_string_aggregator_plugin.reload.error_message
    end

    test "Should raise an error if the provided input property does not exist on the output API namespace" do
        @output_api_namespace.properties.delete("tags")
        @output_api_namespace.save

        perform_enqueued_jobs do
            @unique_string_aggregator_plugin.run
            Sidekiq::Worker.drain_all
        end

        expected_error_message = "Input property does not exist on the output API namespace"
        assert_equal expected_error_message, @unique_string_aggregator_plugin.reload.error_message
    end

    test "An API resource for output API namespace is created for each unique string" do
        tags_one = ['animation', 'family', 'disney']
        tags_two = ['animation', 'family', 'comedy']
        unique_tags = ['animation', 'family', 'disney', 'comedy']

        ApiResource.create(api_namespace_id: @api_namespace.id, properties: {"title" => "The Lion King", "tags" => tags_one})
        ApiResource.create(api_namespace_id: @api_namespace.id, properties: {"title" => "Kung Fu Panda", "tags" => tags_two})

        perform_enqueued_jobs do
            @unique_string_aggregator_plugin.run
            Sidekiq::Worker.drain_all
        end

        assert_equal unique_tags.length, @output_api_namespace.api_resources.length
    end

    test "New API resources are not created for duplicate strings with uppercase letters and whitespace" do
        tags_one = ['animation', 'family', 'disney']
        tags_two = ['   Animation   ', 'FAMILY', 'comedy']
        unique_tags = ['animation', 'family', 'disney', 'comedy']

        ApiResource.create(api_namespace_id: @api_namespace.id, properties: {"title" => "The Lion King", "tags" => tags_one})
        ApiResource.create(api_namespace_id: @api_namespace.id, properties: {"title" => "Kung Fu Panda", "tags" => tags_two})

        perform_enqueued_jobs do
            @unique_string_aggregator_plugin.run
            Sidekiq::Worker.drain_all
        end

        assert_equal unique_tags.length, @output_api_namespace.api_resources.length
    end

    test "Properties hash of each API resource of the output API namespace has the correct keys and values" do
        tags_one = ['animation', 'family', 'disney']
        tags_two = ['animation', 'family', 'comedy', 'martial arts']
        unique_tags = ['animation', 'family', 'disney', 'comedy', 'martial arts']
        input_property_name = @unique_string_aggregator_plugin.metadata["INPUT_PROPERTY"]
        expected_api_resource_props = [
            {"tags" => "animation", "representation" => "Animation"},
            {"tags" => "family", "representation" => "Family"},
            {"tags" => "disney", "representation" => "Disney"},
            {"tags" => "comedy", "representation" => "Comedy"},
            {"tags" => "martial arts", "representation" => "Martial Arts"}
        ]

        ApiResource.create(api_namespace_id: @api_namespace.id, properties: {"title" => "The Lion King", "tags" => tags_one})
        ApiResource.create(api_namespace_id: @api_namespace.id, properties: {"title" => "Kung Fu Panda", "tags" => tags_two})

        perform_enqueued_jobs do
            @unique_string_aggregator_plugin.run
            Sidekiq::Worker.drain_all
        end

        @output_api_namespace.api_resources.each_with_index do |api_resource, i|
            assert_equal expected_api_resource_props[i], api_resource.properties
        end
    end

    test "Existing API resources of the output API namespace are removed if PRISTINE is set to true" do
        input_property_name = @unique_string_aggregator_plugin.metadata["INPUT_PROPERTY"]

        resource_one = ApiResource.create(api_namespace_id: @output_api_namespace.id, properties: {input_property_name => "animation", "representation" => "animation"})
        resource_two = ApiResource.create(api_namespace_id: @output_api_namespace.id, properties: {input_property_name => "family", "representation" => "family"})

        ApiResource.create(api_namespace_id: @api_namespace.id, properties: {"title" => "The Lion King", "tags" => ['animation', 'family', 'disney']})

        perform_enqueued_jobs do
            @unique_string_aggregator_plugin.run
            Sidekiq::Worker.drain_all
        end

        assert_equal 3, @output_api_namespace.api_resources.length
        assert_not(@output_api_namespace.api_resources.include?(resource_one))
        assert_not(@output_api_namespace.api_resources.include?(resource_two))
    end

    test "Existing API resources of the output API namespace are not removed If PRISTINE is set to false" do
        metadata = @unique_string_aggregator_plugin.metadata
        metadata["PRISTINE"] = false
        @unique_string_aggregator_plugin.update(metadata: metadata)

        input_property_name = metadata["INPUT_PROPERTY"]

        resource_one = ApiResource.create(api_namespace_id: @output_api_namespace.id, properties: {input_property_name => "animation", "representation" => "animation"})
        resource_two = ApiResource.create(api_namespace_id: @output_api_namespace.id, properties: {input_property_name => "family", "representation" => "family"})

        perform_enqueued_jobs do
            @unique_string_aggregator_plugin.run
            Sidekiq::Worker.drain_all
        end

        assert(ApiResource.exists?(api_namespace_id: @output_api_namespace.id, id: resource_one.id))
        assert(ApiResource.exists?(api_namespace_id: @output_api_namespace.id, id: resource_two.id))

        assert_equal 2, @output_api_namespace.reload.api_resources.length
    end

    test "API resources under the output API namespace are created only for new unique strings If PRISTINE is set to false" do
        metadata = @unique_string_aggregator_plugin.metadata
        metadata["PRISTINE"] = false
        @unique_string_aggregator_plugin.update(metadata: metadata)

        input_property_name = metadata["INPUT_PROPERTY"]

        resource_one = ApiResource.create(api_namespace_id: @output_api_namespace.id, properties: {input_property_name => "animation", "representation" => "animation"})
        resource_two = ApiResource.create(api_namespace_id: @output_api_namespace.id, properties: {input_property_name => "family", "representation" => "family"})

        ApiResource.create(api_namespace_id: @api_namespace.id, properties: {"title" => "The Lion King", "tags" => ['animation', 'family', 'disney']})

        # disney is the new tag, so only 1 API resource should be created
        assert_difference "@output_api_namespace.reload.api_resources.length", +1 do
            perform_enqueued_jobs do
                @unique_string_aggregator_plugin.run
                Sidekiq::Worker.drain_all
            end
        end
    end
end