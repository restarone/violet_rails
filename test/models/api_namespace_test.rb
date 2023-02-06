require "test_helper"

class ApiNamespaceTest < ActiveSupport::TestCase
  setup do
    @subdomain = subdomains(:public)
    @subdomain.update(api_plugin_events_enabled: true)
    @subdomain_events_api = api_namespaces(:plugin_subdomain_events)
    @subdomain_events_api.api_resources.destroy_all
    @message_thread = message_threads(:public)
    @message = @message_thread.messages.create!(content: "Hello")
    Sidekiq::Testing.fake!
  end

  test "plugin: subdomain/subdomain_events -> tracks message creation by creating ApiResource" do
    service = ApiNamespace::Plugin::V1::SubdomainEventsService.new(@message)
    assert_difference "ApiResource.count", +1 do      
      service.track_event
      Sidekiq::Worker.drain_all
    end
    resource = @subdomain_events_api.api_resources.reload.last
    model =  resource.properties["model"]
    representation =  resource.properties["representation"]
    assert_equal ["model", "representation"].sort, resource.properties.keys.sort
    assert_equal ["record_id", "record_type"].sort, model.keys.sort
    assert_equal model["record_type"].constantize, Message
    assert model["record_type"].constantize.send(:find, model["record_id"])
    assert_equal representation["body"].class, String
  end

  test "plugin: subdomain/subdomain_events -> tracks message creation by creating ApiResource & running actions" do
    service = ApiNamespace::Plugin::V1::SubdomainEventsService.new(@message)
    assert_difference "ApiResource.count", +1 do      
      service.track_event
      Sidekiq::Worker.drain_all
    end

    assert_equal @subdomain_events_api.reload.executed_api_actions.first.lifecycle_stage, 'complete'
  end

  test "plugin: subdomain/subdomain_events -> should run actions only once" do
    CreateApiAction.any_instance.expects(:execute_action).times(@subdomain_events_api.api_actions.size)

    service = ApiNamespace::Plugin::V1::SubdomainEventsService.new(@message)
    assert_difference "ApiResource.count", +1 do      
      service.track_event
      Sidekiq::Worker.drain_all
    end
  end

  test "should check the associated CMS entities: Page, Layout and Snippet for the api-namespace if the api-form snippet is content of them" do
    namespace = api_namespaces(:users)
    api_form = api_forms(:one)
    api_form.update!(api_namespace: namespace)

    layout = comfy_cms_layouts(:default)
    page = comfy_cms_pages(:root)
    snippet = comfy_cms_snippets(:public)

    namespace_snippet = namespace.snippet

    layout.update!(content: namespace_snippet)
    snippet.update!(content: namespace_snippet)
    page.fragments.create!(content: namespace_snippet, identifier: 'content')

    associations = namespace.cms_associations

    assert_includes associations, layout
    assert_includes associations, page
    assert_includes associations, snippet
  end

  test "should check the associated CMS Snippet if snippet's identifier is namespace_slug or namespace_slug-show" do
    namespace = api_namespaces(:users)

    snippet = comfy_cms_snippets(:public)
    snippet.update!(identifier: namespace.slug)
    associations = namespace.cms_associations

    assert_includes associations, snippet

    snippet.update!(identifier: "#{namespace.slug}-show")
    associations = namespace.cms_associations

    assert_includes associations, snippet
  end

  test "should check the associated CMS Page of the api-namespace if the API HTML renderer is content of the page" do
    namespace = api_namespaces(:users)
    page = comfy_cms_pages(:root)
    page.fragments.create!(content: "{{ cms:helper render_api_namespace_resource '#{namespace.slug}', scope: { properties: { published: 'true' } }, order: { created_at: 'DESC' } }}", identifier: 'content')
    associations = namespace.cms_associations

    assert_includes associations, page
  end

  test "should check the associated CMS Page of the api-namespace if the API HTML renderer is content of the page with newlines" do
    namespace = api_namespaces(:users)
    page = comfy_cms_pages(:root)
    page.fragments.create!(content: "<div class=\"p-4 details-page\">\r\n\t<div class=\"restrictive-container main__content-container\">\r\n\t\t{{cms:helper render_api_namespace_resource '#{namespace.slug}', scope: { properties: { published: 'true' } }}}\r\n\t</div>\r\n</div>", identifier: 'content')
    associations = namespace.cms_associations

    assert_includes associations, page

    page.fragments.first.update!(content: "<p><strong>Tester: User Acceptance and Quality Assurance</strong>\r\n</p>\r\n<p>\r\n\tAs a tester at Restarone you will closely evaluate software before it is released to be used by thousands of people.\r\n</p>\r\n<p>\r\n\tIf you’re a tester with 0-2 years of experience looking to improve software products, then this is for you!\r\n</p>\r\n<p>\r\n\tComplete the form below to start the application process:\r\n</p>\r\n<p>{{ cms:helper render_api_namespace_resource_index '#{namespace.slug}', scope: { properties:  { property: value } } }}\r\n</p>\r\n<p>By submitting the form above, you consent to Restarone Solutions Inc. storing your information and reaching out for relevant opportunities.\r\n</p>")
    associations = namespace.cms_associations

    assert_includes associations, page
  end

  test "should check the associated CMS Page, Layout, Snippet of the api-namespace if the API form is rendered as content with newlines" do
    namespace = api_namespaces(:users)
    api_form = api_forms(:one)
    api_form.update!(api_namespace: namespace)

    layout = comfy_cms_layouts(:default)
    snippet = comfy_cms_snippets(:public)
    page = comfy_cms_pages(:root)

    content = "<div class=\"contact-us-form\">\r\n\t<h3>Send us a message</h3>\r\n\t#{namespace.snippet}\r\n</div>\r\n"

    layout.update!(content: content)
    snippet.update!(content: content)
    page.fragments.create!(content: content, identifier: 'content')

    associations = namespace.cms_associations

    assert_includes associations, page
    assert_includes associations, layout
    assert_includes associations, snippet

    new_content = "<p><strong>Tester: User Acceptance and Quality Assurance</strong>\r\n</p>\r\n<p>\r\n\tAs a tester at Restarone you will closely evaluate software before it is released to be used by thousands of people.\r\n</p>\r\n<p>\r\n\tIf you’re a tester with 0-2 years of experience looking to improve software products, then this is for you!\r\n</p>\r\n<p>\r\n\tComplete the form below to start the application process:\r\n</p>\r\n<p>#{namespace.snippet}\r\n</p>\r\n<p>By submitting the form above, you consent to Restarone Solutions Inc. storing your information and reaching out for relevant opportunities.\r\n</p>"

    layout.update!(content: new_content)
    snippet.update!(content: new_content)
    page.fragments.first.update!(content: new_content)

    associations = namespace.cms_associations

    assert_includes associations, page
    assert_includes associations, layout
    assert_includes associations, snippet
  end
end
