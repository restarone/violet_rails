require "test_helper"

class Comfy::Admin::Cms::LayoutsControllerTest < ActionDispatch::IntegrationTest
  test '#index: shows only layouts with provided categories' do
    site = Comfy::Cms::Site.first  
    user = User.find_by_email('test@restarone.solutions')

    layout_one = site.layouts.create!(identifier: "first")
    layout_two = site.layouts.create!(identifier: "second")
    layout_three = site.layouts.create!(identifier: "third")
  
    category_one = comfy_cms_categories(:layout_1)
    category_two = comfy_cms_categories(:layout_2)

    layout_one.update!(category_ids: [category_one.id])
    layout_two.update!(category_ids: [category_one.id])
    layout_three.update!(category_ids: [category_two.id])

    sign_in(user)
    get comfy_admin_cms_site_layouts_url(site_id: site.id), params: { categories: category_one.label}
    assert_response :success

    categorized_layout_ids = [layout_one.id, layout_two.id]
    @controller.view_assigns['layouts'].each do |layout|
      assert_includes categorized_layout_ids, layout.id
    end
  end
end
