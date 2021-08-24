require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    page = Comfy::Cms::Page.first
    page.update(is_restricted: false)
    Comfy::Cms::Fragment.create!(
      identifier: 'content',
      record: page,
      tag: 'wysiwyg',
      content: "<h1>Hello</h1>"
    )
  end

  test "#query" do
    get comfy_cms_render_page_path('/')
    post query_url, params: {query: 'Hello'}, as: :json
    json_response = JSON.parse(response.body)
    assert_equal json_response.class, Array
    assert json_response.size > 0
    attributes = ["id", "site_id", "layout_id", "parent_id", "target_page_id", "label", "slug", "full_path", "content_cache", "position", "children_count", "is_published", "created_at", "updated_at", "is_restricted", "preview_content"]
    result = json_response.sample
    assert_equal attributes.sort, result.keys.sort
  end

  test "#query raises error if no search parameter is defined" do
    get comfy_cms_render_page_path('/')
    post query_url, as: :json
    json_response = JSON.parse(response.body)
    assert_equal json_response["code"], 422
  end
end
