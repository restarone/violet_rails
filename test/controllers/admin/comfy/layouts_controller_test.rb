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

  test 'allows #index and redirects to #new if no layouts are present' do
    site = comfy_cms_sites(:public)
    Comfy::Cms::Layout.delete_all
    
    user = users(:public)
    user.update(can_access_admin: true, can_manage_web: true)
    sign_in(user)
    get comfy_admin_cms_site_layouts_url(site_id: site.id)

    assert_response :redirect
    assert_redirected_to action: :new
  end

  test 'denies #index if not permissioned' do
    sign_in(@user)
    get comfy_admin_cms_site_layouts_url(subdomain: @restarone_subdomain, site_id: @site.id)
    assert_response :redirect
  end

  test "allows #new if permissioned" do
    @user.update(can_access_admin: true, can_manage_web: true)
    sign_in(@user)
    get new_comfy_admin_cms_site_layout_url(subdomain: @restarone_subdomain, site_id: @site.id)

    assert_response :success
    assert assigns(:layout)
    assert_equal "{{ cms:wysiwyg content }}", assigns(:layout).content
    assert_template :new
    assert_select "form[action='/admin/sites/#{@site.id}/layouts']"
  end

  test "allows #new with parent if permissioned" do
    site = comfy_cms_sites(:public)
    layout = comfy_cms_layouts(:default)
    layout.update_column(:app_layout, "application")

    user = users(:public)
    user.update(can_access_admin: true, can_manage_web: true)
    sign_in(user)
    get new_comfy_admin_cms_site_layout_url(site_id: site.id), params: { parent_id: layout.id }

    assert_response :success
    assert_equal layout.app_layout, assigns(:layout).app_layout
    assert_template :new
    assert_select "form[action='/admin/sites/#{site.id}/layouts']"
  end

  test 'denies #new if not permissioned' do
    sign_in(@user)
    get new_comfy_admin_cms_site_layout_url(subdomain: @restarone_subdomain, site_id: @site.id)
    assert_response :redirect
  end

  test 'allows #edit if permissioned' do
    site = comfy_cms_sites(:public)
    layout = comfy_cms_layouts(:default)
    
    user = users(:public)
    user.update(can_access_admin: true, can_manage_web: true)
    sign_in(user)
    get edit_comfy_admin_cms_site_layout_url(site_id: site.id, id: layout.id)

    assert_response :success
    assert assigns(:layout)
    assert_template :edit
    assert_select "form[action='/admin/sites/#{layout.site.id}/layouts/#{layout.id}']"
  end

  test 'denies #edit if layout not found' do
    site = comfy_cms_sites(:public)
    
    user = users(:public)
    user.update(can_access_admin: true, can_manage_web: true)
    sign_in(user)
    get edit_comfy_admin_cms_site_layout_url(site_id: site.id, id: "invalid")

    assert_response :redirect
    assert_redirected_to action: :index
    assert_equal "Layout not found", flash[:danger]
  end

  test 'denies #edit if not permissioned' do
    sign_in(@user)
    get edit_comfy_admin_cms_site_layout_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end

  test 'allows #update if permissioned' do
    site = comfy_cms_sites(:public)
    layout = comfy_cms_layouts(:default)

    user = users(:public)
    user.update(can_access_admin: true, can_manage_web: true)
    sign_in(user)
    put comfy_admin_cms_site_layout_url(site_id: site.id, id: layout.id), params: { layout: {
      label:    "New Label",
      content:  "New {{cms:page:content}}"
    } }

    assert_response :redirect
    assert_redirected_to action: :edit, site_id: layout.site, id: layout
    assert_equal "Layout updated", flash[:success]
    layout.reload
    assert_equal "New Label", layout.label
    assert_equal "New {{cms:page:content}}", layout.content
  end

  test 'denies #update if proper details are not provided' do
    site = comfy_cms_sites(:public)
    layout = comfy_cms_layouts(:default)

    user = users(:public)
    user.update(can_access_admin: true, can_manage_web: true)
    sign_in(user)
    put comfy_admin_cms_site_layout_url(site_id: site.id, id: layout.id), params: { layout: {
      identifier: ""
    } }

    assert_response :success
    assert_template :edit
    layout.reload
    assert_not_equal "", layout.identifier
    assert_equal "Failed to update layout", flash[:danger]
  end

  test 'denies #update if not permissioned' do
    sign_in(@user)
    patch comfy_admin_cms_site_layout_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end

  test 'allows #destroy if permissioned' do
    site = comfy_cms_sites(:public)
    layout = comfy_cms_layouts(:default)

    user = users(:public)
    user.update(can_access_admin: true, can_manage_web: true)

    assert_difference "Comfy::Cms::Layout.count", -1 do
      sign_in(user)
      delete comfy_admin_cms_site_layout_url(site_id: site.id, id: layout.id)
    end

    assert_response :redirect
    assert_redirected_to action: :index
    assert_equal "Layout deleted", flash[:success]
  end

  test 'denies #destroy if not permissioned' do
    sign_in(@user)
    delete comfy_admin_cms_site_layout_url(subdomain: @restarone_subdomain, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end

  test 'allows #reorder' do
    site = comfy_cms_sites(:public)
    layout_one = comfy_cms_layouts(:default)
    layout_two = site.layouts.create!(
      label:      "test",
      identifier: "test"
    )
    assert_equal 0, layout_one.position
    assert_equal 1, layout_two.position

    user = users(:public)
    user.update(can_access_admin: true, can_manage_web: true)
    sign_in(user)

    put reorder_comfy_admin_cms_site_layouts_url(site_id: site.id), params: {
      order: [layout_two.id, layout_one.id]
    }
    assert_response :success
    layout_one.reload
    layout_two.reload

    assert_equal 1, layout_one.position
    assert_equal 0, layout_two.position
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
