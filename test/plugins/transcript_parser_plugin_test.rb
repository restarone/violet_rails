require "test_helper"

class TranscriptParserPluginTest < ActiveSupport::TestCase
    setup do
        @transcript_parser_plugin = external_api_clients(:transcript_parser_plugin)
        @api_namespace = @transcript_parser_plugin.api_namespace
        @transcript = api_resources(:transcript)
        Sidekiq::Testing.fake!
    end

    # How test fixtures are set up:
    # By default, transcript_parsed is set to false
    # By default, transcript property is empty, i.e. no parsed transcript

    test "Should raise an error if the provided input and output string properties are the same" do
        metadata = {
            "INPUT_STRING_PROPERTY": "raw_transcript",
            "OUTPUT_STRING_PROPERTY": "raw_transcript",
        }
        @transcript_parser_plugin.update(metadata: metadata)

        perform_enqueued_jobs do
            @transcript_parser_plugin.run
            Sidekiq::Worker.drain_all
        end

        expected_error_message = "Input and output string properties cannot be the same (no overwriting allowed)"
        assert_equal expected_error_message, @transcript_parser_plugin.reload.error_message
    end

    test "Should raise an error if the provided input string property does not exist" do
        metadata = @transcript_parser_plugin.metadata
        metadata["INPUT_STRING_PROPERTY"] = "non-existent property"
        @transcript_parser_plugin.update(metadata: metadata)

        perform_enqueued_jobs do
            @transcript_parser_plugin.run
            Sidekiq::Worker.drain_all
        end

        expected_error_message = "The specified input string property does not exist"
        assert_equal expected_error_message, @transcript_parser_plugin.reload.error_message
    end

    test "Should raise an error if the provided output string property does not exist" do
        metadata = @transcript_parser_plugin.metadata
        metadata["OUTPUT_STRING_PROPERTY"] = "non-existent property"
        @transcript_parser_plugin.update(metadata: metadata)

        perform_enqueued_jobs do
            @transcript_parser_plugin.run
            Sidekiq::Worker.drain_all
        end

        expected_error_message = "The specified output string property does not exist"
        assert_equal expected_error_message, @transcript_parser_plugin.reload.error_message
    end

    test "Should not parse transcript if it has already been parsed" do
        @transcript.properties["transcript_parsed"] = true
        @transcript.save

        perform_enqueued_jobs do
            @transcript_parser_plugin.run
            Sidekiq::Worker.drain_all
        end

        assert(@transcript.reload.properties["transcript"].empty?)
    end

    test "Transcript is parsed correctly" do
        raw_transcript = "1\n00:00:00,300 --> 00:00:02,167\n[sally]: i'm in los angeles and\n\n2\n00:00:01,920 --> 00:00:02,102\n[bobby]: okay\n\n3\n00:00:03,151 --> 00:00:04,737\n[sally]: maybe possibly\n\n4\n00:00:05,780 --> 00:00:13,613\n[bobby78]: $ oh maybe ye so nice an is a\nsupporter financial supporter of hollows\n\n5\n00:00:13,345 --> 00:00:15,510\n[sally]: 10 s yeah\n10 hello world\nhi there\n$10 in my wallet"
        properties = {"raw_transcript": raw_transcript, "transcript": "", "transcript_parsed": false}
        transcript_resource = ApiResource.create(api_namespace_id: @api_namespace.id, properties: properties)
        expected_parsed_transcript = "i'm in los angeles and okay maybe possibly $ oh maybe ye so nice an is a supporter financial supporter of hollows 10 s yeah 10 hello world hi there $10 in my wallet"
        
        perform_enqueued_jobs do
            @transcript_parser_plugin.run
            Sidekiq::Worker.drain_all
        end
    
        assert_equal expected_parsed_transcript, transcript_resource.reload.properties["transcript"]
    end

    test "Transcript with leading and trailing whitespace is parsed correctly" do
        raw_transcript = "      1\n00:00:00,300 --> 00:00:02,167\n[sally]: i'm in los angeles and\n\n2\n00:00:01,920 --> 00:00:02,102\n[bobby]: okay\n\n3\n00:00:03,151 --> 00:00:04,737\n[sally]: maybe possibly\n\n4\n00:00:05,780 --> 00:00:13,613\n[bobby78]: $ oh maybe ye so nice an is a\nsupporter financial supporter of hollows\n\n5\n00:00:13,345 --> 00:00:15,510\n[sally]: 10 s yeah     "
        properties = {"raw_transcript": raw_transcript, "transcript": "", "transcript_parsed": false}
        transcript_resource = ApiResource.create(api_namespace_id: @api_namespace.id, properties: properties)
        expected_parsed_transcript = "i'm in los angeles and okay maybe possibly $ oh maybe ye so nice an is a supporter financial supporter of hollows 10 s yeah"
        
        perform_enqueued_jobs do
            @transcript_parser_plugin.run
            Sidekiq::Worker.drain_all
        end
    
        assert_equal expected_parsed_transcript, transcript_resource.reload.properties["transcript"]
    end
end