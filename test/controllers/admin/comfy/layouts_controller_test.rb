require "test_helper"

class Comfy::Admin::Cms::LayoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      @site = Comfy::Cms::Site.first
      @user = User.first
      @layout = @site.layouts.last
      @page = @layout.pages.last
    end
  end

  test 'allows #index if permissioned' do
    @user.update(can_access_admin: true)
    sign_in(@user)
    get comfy_admin_cms_site_layouts_url(subdomain: @restarone_subdomain, site_id: @site.id)
    assert_template :index
    assert_response :success
  end

  test 'denies #index if not permissioned' do
    sign_in(@user)
    get comfy_admin_cms_site_layouts_url(subdomain: @restarone_subdomain, site_id: @site.id)
    assert_response :redirect
  end


  test 'denies #new if not permissioned' do
    sign_in(@user)
    get new_comfy_admin_cms_site_layout_url(subdomain: @restarone_subdomain, site_id: @site.id)
    assert_response :redirect
  end

  test 'denies #edit if not permissioned' do
    sign_in(@user)
    get edit_comfy_admin_cms_site_layout_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end

  test 'denies #update if not permissioned' do
    sign_in(@user)
    patch comfy_admin_cms_site_layout_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end

  test 'denies #destroy if not permissioned' do
    sign_in(@user)
    delete comfy_admin_cms_site_layout_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end

  test '#index: shows only layouts with provided categories' do
    site = comfy_cms_sites(:public) 
    user = users(:one)

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
