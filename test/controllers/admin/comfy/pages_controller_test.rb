require "test_helper"

class Comfy::Admin::Cms::PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @site = Comfy::Cms::Site.first
      @user = User.first
      @user.update(can_access_admin: true)
      @layout = @site.layouts.last
      @page = @layout.pages.last
    end
  end

  test 'allows #index if permissioned' do
    sign_in(@user)
    get comfy_admin_cms_site_pages_url(subdomain: @restarone_subdomain.name, site_id: @site.id)
    assert_template :index
    assert_response :success
  end

  test 'denies #index if not permissioned' do
    @user.update(can_access_admin: false)
    sign_in(@user)
    get comfy_admin_cms_site_pages_url(subdomain: @restarone_subdomain.name, site_id: @site.id)
    assert_response :redirect
  end

  test 'denies #new if not permissioned' do
    @user.update(can_access_admin: false)
    sign_in(@user)
    get new_comfy_admin_cms_site_page_url(subdomain: @restarone_subdomain.name, site_id: @site.id)
    assert_response :redirect
  end

  test 'denies #edit if not permissioned' do
    @user.update(can_access_admin: false)
    sign_in(@user)
    get edit_comfy_admin_cms_site_page_url(subdomain: @restarone_subdomain.name, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end

  test 'denies #update if not permissioned' do
    sign_in(@user)
    patch comfy_admin_cms_site_page_url(subdomain: @restarone_subdomain.name, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end


  test 'denies #destroy if not permissioned' do
    sign_in(@user)
    delete comfy_admin_cms_site_page_url(subdomain: @restarone_subdomain.name, site_id: @site.id, id: @page.id)
    assert_response :redirect
  end

  test 'tracks page update (if tracking is enabled)' do
    @restarone_subdomain.update(tracking_enabled: true)

    Apartment::Tenant.switch @restarone_subdomain.name do
      @user.update(can_access_admin: true, can_manage_web: true)
      sign_in(@user)

      assert_difference "Ahoy::Event.count", +1 do
        patch comfy_admin_cms_site_page_url(subdomain: @restarone_subdomain.name, site_id: @site, id: @page), params: { page: {
          label:      "Updated Label",
          fragments_attributes: [
            { identifier: "content",
              content:    "new_page_text_content" },
            { identifier: "header",
              content:    "new_page_string_content" }
          ]
        } }
      end

    end
    assert_response :redirect
    assert_redirected_to action: :edit, id: @page
  end

  test 'does not track page update (if tracking is enabled)' do
    @restarone_subdomain.update(tracking_enabled: false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      @user.update(can_access_admin: true, can_manage_web: true)
      sign_in(@user)

      assert_no_difference "Ahoy::Event.count", +1 do
        patch comfy_admin_cms_site_page_url(subdomain: @restarone_subdomain.name, site_id: @site, id: @page), params: { page: {
          label:      "Updated Label",
          fragments_attributes: [
            { identifier: "content",
              content:    "new_page_text_content" },
            { identifier: "header",
              content:    "new_page_string_content" }
          ]
        } }
      end
    end
    assert_response :redirect
    assert_redirected_to action: :edit, id: @page
  end
end
