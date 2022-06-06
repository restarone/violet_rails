# frozen_string_literal: true

require "test_helper"

class Comfy::Admin::Cms::FilesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
      @restarone_user.update(can_access_admin: true, can_manage_files: true)

      @site = Comfy::Cms::Site.first
      @file = @site.files.create(
        label:        "test",
        description:  "test file",
        file:         fixture_file_upload("fixture_image.png", "image/jpeg")
      )
    end
  end

  test 'tracks file update (if tracking is enabled)' do
    @restarone_subdomain.update(tracking_enabled: true)

    Apartment::Tenant.switch @restarone_subdomain.name do
      sign_in(@restarone_user)

      assert_difference "Ahoy::Event.count", +1 do
        patch comfy_admin_cms_site_file_url(subdomain: @restarone_subdomain.name, site_id: @site, id: @file), params: { file: {
          label:       "Updated File",
          description: "Updated Description",
          file:        fixture_file_upload("fixture_image.png", "image/jpeg")
        } }
      end

    end
    assert_response :redirect
    assert_redirected_to action: :edit, site_id: @site, id: @file
  end

  test 'does not track file update (if tracking is enabled)' do
    @restarone_subdomain.update(tracking_enabled: false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      sign_in(@restarone_user)

      assert_no_difference "Ahoy::Event.count", +1 do
        patch comfy_admin_cms_site_file_url(subdomain: @restarone_subdomain.name, site_id: @site, id: @file), params: { file: {
          label:       "Updated File",
          description: "Updated Description",
          file:        fixture_file_upload("fixture_image.png", "image/jpeg")
        } }
      end
    end
    assert_response :redirect
    assert_redirected_to action: :edit, site_id: @site, id: @file
  end

end
