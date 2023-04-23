require "test_helper"

class ComplianceVisitorDataRequestPluginTest < ActiveSupport::TestCase
  setup do
    @data_request_plugin = external_api_clients(:compliance_visitor_data_request_plugin)
    @visitor_api_namespace = api_namespaces(:compliance_visitor_data_request)
    @visitor_one = api_resources(:compliance_visitor_data_request_one)
    @visitor_two = api_resources(:compliance_visitor_data_request_two)

    @namespace_with_email_one = api_namespaces(:compliance_visitor_target_one)
    @namespace_with_email_two = api_namespaces(:compliance_visitor_target_two)

    Sidekiq::Testing.fake!

    # How test fixtures are set up:
    # By default, "compliance_message_sent" of each visitor api resource is false
    # By default, each visitor has no submission in an api namespace
  end

  test "Should not send email to visitor if they already received one" do
    @visitor_one.properties["compliance_message_sent"] = true
    @visitor_one.save
    @visitor_two.properties["compliance_message_sent"] = true
    @visitor_two.save

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        @data_request_plugin.run
        Sidekiq::Worker.drain_all
      end
    end
  end

  test "Should send email if compliance_message_sent is set to false on the API resource" do
    # Visitor one and two are making a submission under namespace_with_email_one
    ApiResource.create(api_namespace_id: @namespace_with_email_one.id, properties: {"post": "Hello world", "email": @visitor_one.properties["email"]})
    ApiResource.create(api_namespace_id: @namespace_with_email_one.id, properties: {"post": "Hello world", "email": @visitor_two.properties["email"]})
    assert_difference "ActionMailer::Base.deliveries.size", +2 do
      perform_enqueued_jobs do
        @data_request_plugin.run
        Sidekiq::Worker.drain_all
      end 
    end
  end

  test "Sender and recipient email addresses and body message are correct" do
    visitor_email = @visitor_one.properties["email"]
    ApiResource.create(api_namespace_id: @namespace_with_email_one.id, properties: {"post": "Hello world", "email": visitor_email})

    expected_message = @data_request_plugin.metadata["MESSAGE"]

    perform_enqueued_jobs do
      @data_request_plugin.run
      Sidekiq::Worker.drain_all
    end

    sent_email = ActionMailer::Base.deliveries.last

    # sent_email.from returns a string in development, but in production it returns an array
    assert(Array.wrap(sent_email.from).first.include?(Subdomain.current.name))
    assert(Array.wrap(sent_email.from).first.include?(ENV["APP_HOST"]))
    assert(sent_email.to.include?(visitor_email))
    assert(sent_email.parts.first.body.raw_source.include?(expected_message))
  end

  test "Should not scan excluded api namespaces" do
    @data_request_plugin.metadata["EXCLUDE_API_NAMESPACES"] << @namespace_with_email_one.slug
    @data_request_plugin.save
    visitor_email = @visitor_one.properties["email"]
    ApiResource.create(api_namespace_id: @namespace_with_email_one.id, properties: {"post": "Hello world", "email": visitor_email})
    # Should not send an email even if a submission was made under a namespace since it's excluded
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        @data_request_plugin.run
        Sidekiq::Worker.drain_all
      end
    end
  end

  test "Email should contain a CSV attachment per API Namespace" do
    visitor_email = @visitor_one.properties["email"]
    ApiResource.create(api_namespace_id: @namespace_with_email_one.id, properties: {"post": "Hello world", "email": visitor_email})
    ApiResource.create(api_namespace_id: @namespace_with_email_two.id, properties: {"name": "Test Name", "email": visitor_email})

    perform_enqueued_jobs do
      @data_request_plugin.run
      Sidekiq::Worker.drain_all
    end

    # Visitor one making submissions under two namespaces, so the email should contain two attachments
    sent_email = ActionMailer::Base.deliveries.last
    first_attachment_content = sent_email.attachments[0].body.raw_source.gsub(/\r/, "")
    second_attachment_content = sent_email.attachments[1].body.raw_source.gsub(/\r/, "")

    assert_equal 2, sent_email.attachments.length

    sent_email.attachments.each do |attachment|
      assert(attachment.content_type.start_with?("text/csv"))
    end

    assert_not(first_attachment_content == second_attachment_content)

    @namespace_with_email_one.properties.each do |key, value|
      assert(first_attachment_content.include?(key))
      assert(first_attachment_content.include?(value))
    end

    @namespace_with_email_two.properties.each do |key, value|
      assert(second_attachment_content.include?(key))
      assert(second_attachment_content.include?(value))
    end
  end

  test "CSV file should be named according to the API Namespace and have file extension .csv" do
    visitor_email = @visitor_one.properties["email"]
    ApiResource.create(api_namespace_id: @namespace_with_email_one.id, properties: {"post": "Hello world", "email": visitor_email})

    perform_enqueued_jobs do
      @data_request_plugin.run
      Sidekiq::Worker.drain_all
    end

    sent_email = ActionMailer::Base.deliveries.last

    assert sent_email
    assert sent_email.attachments[0].filename.include?("api_namespace_#{@namespace_with_email_one.slug}")
    assert sent_email.attachments[0].filename.include?(".csv")
  end

  test "CSV file should contain the right content" do
    visitor_email = @visitor_one.properties["email"]
    api_resource = ApiResource.create(api_namespace_id: @namespace_with_email_one.id, properties: {"post": "Hello world", "email": visitor_email})

    @namespace_with_email_one.non_primitive_properties.create([
      {
        label: 'richtext',
        field_type: 'richtext'
      }
    ])

    api_resource.non_primitive_properties.create([
      {
        label: 'richtext',
        field_type: 'richtext',
        content: "<div>Hello World</div>"
      }
    ])

    richtext = api_resource.non_primitive_properties.find_by(label: "richtext").content.to_s

    expected_csv = CSV.generate do |csv|
      csv << ["id", "api_namespace_id", "post", "email", "created_at", "updated_at", "richtext"]
      csv << [api_resource.id, api_resource.api_namespace_id, api_resource.properties["post"], api_resource.properties["email"], api_resource.created_at, api_resource.updated_at, richtext]
    end

    perform_enqueued_jobs do
      @data_request_plugin.run
      Sidekiq::Worker.drain_all
    end

    sent_email = ActionMailer::Base.deliveries.last
    assert_equal expected_csv, sent_email.attachments.first.body.raw_source.gsub(/\r/, "")
  end

  test "Should raise an exception if admin does not exclude any api namespace and does not grant explicit permission to scan all API Namespaces" do
    @data_request_plugin.metadata["EXCLUDE_API_NAMESPACES"] = []
    @data_request_plugin.metadata["SCAN_ALL_NAMESPACES"] = false
    @data_request_plugin.save

    perform_enqueued_jobs do
      @data_request_plugin.run
      Sidekiq::Worker.drain_all
    end 

    expected_error_message = "Permission to scan all api namespaces is not given"
    assert_equal expected_error_message, @data_request_plugin.reload.error_message
  end

  test "A message thread with a message is created when email is sent" do
    visitor_email = @visitor_one.properties["email"]
    ApiResource.create(api_namespace_id: @namespace_with_email_one.id, properties: {"post": "Hello world", "email": visitor_email})

    assert_difference "MessageThread.all.length", +1 do
      assert_difference "Message.all.length", +1 do
        perform_enqueued_jobs do
          @data_request_plugin.run
          Sidekiq::Worker.drain_all
        end 
      end
    end
  end

  test "Message contains rich text content with a CSV attachment per API namespace" do
    visitor_email = @visitor_one.properties["email"]
    ApiResource.create(api_namespace_id: @namespace_with_email_one.id, properties: {"post": "Hello world", "email": visitor_email})
    ApiResource.create(api_namespace_id: @namespace_with_email_two.id, properties: {"name": "Test Name", "email": visitor_email})

    perform_enqueued_jobs do
      @data_request_plugin.run
      Sidekiq::Worker.drain_all
    end

    rich_text_content = Message.last.rich_text_content
    attachments = rich_text_content.body.attachments

    assert_not(rich_text_content.blank?)
    assert_equal 2, attachments.length

    attachments.each do |attachment|
      assert_equal "text/csv", attachment[:content_type]
      assert(attachment[:filename].include?(".csv"))
    end
  end
end
