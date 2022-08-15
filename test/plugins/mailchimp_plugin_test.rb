require "test_helper"

class MailchimpPluginTest < ActiveSupport::TestCase
  setup do
    @mailchimp_plugin = external_api_clients(:mailchimp_plugin)
    @api_namespace = api_namespaces(:mailchimp)
    @api_resource = api_resources(:mailchimp)
    @logger_namespace = api_namespaces(:mailchimp_logger)
    @mailchimp_api_uri = "https://#{@mailchimp_plugin.metadata['SERVER_PREFIX']}.api.mailchimp.com/3.0/lists/#{@mailchimp_plugin.metadata['LIST_ID']}/members?skip_merge_validation=true"
    @request_headers = { 'Authorization': "Basic #{@mailchimp_plugin.metadata['API_KEY']}", 'Content-Type': 'application/json' }
    Sidekiq::Testing.fake!
  end

  test "should send api request to mailchimp" do
    metadata = @mailchimp_plugin.metadata

    request_body = { 
      "email_address": @api_resource.properties['email'],
      "status": "subscribed",
      # synced_to_mailchimp property should be excluded by deafult
      # merge fields keys should be uppercase properties keys  
      # tags should be an empty array if TAGS metadata is not defined    
      "merge_fields": {"EMAIL": @api_resource.properties['email'], "FIRST_NAME": @api_resource.properties['first_name'], "LAST_NAME": @api_resource.properties['last_name'], "CONTACT": @api_resource.properties['contact']},
      "tags": []
    }

    response_body = {
      "id" => "123adc",
      "email" => "violet@rails.com"
    }

    mailchimp_request = stub_request(:post, @mailchimp_api_uri)
                            .with(body: request_body, headers: @request_headers)
                            .to_return(status: 200, body: response_body.to_json)

    assert_changes -> { @api_resource.reload.properties['synced_to_mailchimp'] }, from: false, to: true do
      # should not create log if LOGGER_NAMESPACE metadata is not defined 
      assert_no_difference "@logger_namespace.api_resources.count" do
        perform_enqueued_jobs do
          @mailchimp_plugin.run
          Sidekiq::Worker.drain_all
        end
      end
    end

    assert_requested mailchimp_request
  end

  test "should send api request to mailchimp for all unsynced api resources" do
    ApiResource.create(api_namespace_id: @api_namespace.id, properties: {'first_name': 'first_name', 'email': 'some_email@some_domain.com', 'synced_to_mailchimp': false})
    ApiResource.create(api_namespace_id: @api_namespace.id, properties: {'first_name': 'some_name', 'email': 'second@some_domain.com', 'synced_to_mailchimp': true})

    mailchimp_request = stub_request(:post, @mailchimp_api_uri).to_return(status: 200, body: {id: 'some_id'}.to_json)
    expected_count = @api_namespace.api_resources.where("properties @> ?", {synced_to_mailchimp: false}.to_json).count

    perform_enqueued_jobs do
      @mailchimp_plugin.run
      Sidekiq::Worker.drain_all
    end

    assert_requested mailchimp_request, times: expected_count
  end

  test "optional metadata" do
    metadata = @mailchimp_plugin.metadata

    # optional metadata
    metadata['LOGGER_NAMESPACE'] = 'mailchimp_logger'
    metadata['ATTR_TO_EXCLUDE'] = ['first_name']
    metadata['TAGS'] = ['some_tag']
    metadata['CUSTOM_MERGE_FIELDS_MAP'] = {'contact': 'PHONE'}

    @mailchimp_plugin.update(metadata: metadata)

    request_body = { 
      "email_address": @api_resource.properties['email'],
      "status": "subscribed",
      # synced_to_mailchimp property should be excluded by deafult
      # excluded attributes [ATTR_TO_EXCLUDE] should not be present in the merge fields
      # custom_merge_fields should replace default merge field name if CUSTOM_MERGE_FIELDS_MAP is defined eg. CONTACT is replaced by PHONE   
      "merge_fields": {"EMAIL": @api_resource.properties['email'], "LAST_NAME": @api_resource.properties['last_name'], "PHONE": @api_resource.properties['contact']},
      "tags": ['some_tag']
    }

    response_body = {
      "id" => "123adc",
      "email" => "violet@rails.com"
    }

    mailchimp_request = stub_request(:post, @mailchimp_api_uri).with(body: request_body, headers: @request_headers).to_return(status: 200, body: response_body.to_json)

    assert_changes -> { @api_resource.reload.properties['synced_to_mailchimp'] }, from: false, to: true do
      # should create log if LOGGER_NAMESPACE metadata is defined   
      assert_difference "@logger_namespace.api_resources.count", +1 do
        perform_enqueued_jobs do
          @mailchimp_plugin.run
          Sidekiq::Worker.drain_all
        end
      end
    end

    log = @logger_namespace.api_resources.last.properties

    assert_equal log['status'], 'success'
    assert_equal log['api_resource'], @api_resource.id
    assert_equal log['response'], response_body

    assert_requested mailchimp_request
  end

  test "error response: should create log with error status" do
    metadata = @mailchimp_plugin.metadata
    metadata['LOGGER_NAMESPACE'] = 'mailchimp_logger'

    @mailchimp_plugin.update(metadata: metadata)

    response_body = { "message" => "error message" }

    mailchimp_request = stub_request(:post, @mailchimp_api_uri).to_return(status: 400, body: response_body.to_json)

    assert_no_changes @api_resource.reload.properties['synced_to_mailchimp'] do
      # should create log if LOGGER_NAMESPACE metadata is defined   
      assert_difference "@logger_namespace.api_resources.count", +1 do
        perform_enqueued_jobs do
          @mailchimp_plugin.run
          Sidekiq::Worker.drain_all
        end
      end
    end

    log = @logger_namespace.api_resources.last.properties

    assert_equal log['status'], 'error'
    assert_equal log['api_resource'], @api_resource.id
    assert_equal log['response'], response_body

    assert_requested mailchimp_request
  end
end