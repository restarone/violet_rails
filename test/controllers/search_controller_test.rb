require "test_helper"

class SearchControllerControllerTest < ActionDispatch::IntegrationTest
  test "#query" do
    get comfy_cms_render_page_path('/')
    post query_path
  end
end
