# frozen_string_literal: true

require "test_helper"

class Comfy::Admin::Cms::PagesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
      @restarone_user.update(can_access_admin: true, can_manage_web: true)

      @site = Comfy::Cms::Site.first
      @layout = @site.layouts.last
      @page = @layout.pages.last
    end
  end

  test 'tracks page update (if tracking is enabled)' do
    @restarone_subdomain.update(tracking_enabled: true)

    Apartment::Tenant.switch @restarone_subdomain.name do
      sign_in(@restarone_user)

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
      sign_in(@restarone_user)

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
