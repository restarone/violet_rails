# frozen_string_literal: true

require "test_helper"

class Comfy::Admin::Cms::FilesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
      @restarone_user.update(can_access_admin: true, can_manage_web: true, can_manage_files: true)

      @site = Comfy::Cms::Site.first
      @file = @site.files.create(
        label:        "test",
        description:  "test file",
        file:         fixture_file_upload("fixture_image.png", "image/jpeg")
      )
    end
  end

  test "should deny #files if not signed in" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      get comfy_admin_cms_site_files_url(subdomain: @restarone_subdomain.name, site_id: @site)
      assert_redirected_to new_user_session_url(subdomain: @restarone_subdomain.name)
    end
  end

  test "should deny #files if not permissioned" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_manage_files: false)
      sign_in(@restarone_user)

      get comfy_admin_cms_site_files_url(subdomain: @restarone_subdomain.name, site_id: @site)
      assert_response :redirect

      expected_message = "You do not have the permission to do that. Only users who can_manage_files are allowed to perform that action."
      assert_match expected_message, request.flash[:alert]
    end
  end

  test "should deny #files if signed-in and permissioned" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_manage_files: true)
      sign_in(@restarone_user)

      get comfy_admin_cms_site_files_url(subdomain: @restarone_subdomain.name, site_id: @site)
      assert_response :ok
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

  test 'should deny files#update if not permissioned' do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_manage_files: false)
      sign_in(@restarone_user)

      patch comfy_admin_cms_site_file_url(subdomain: @restarone_subdomain.name, site_id: @site, id: @file), params: { file: {
        label:       "Updated File",
        description: "Updated Description",
        file:        fixture_file_upload("fixture_image.png", "image/jpeg")
      } }
    end

    assert_response :redirect
    expected_message = "You do not have the permission to do that. Only users who can_manage_files are allowed to perform that action."
    assert_match expected_message, request.flash[:alert]
    assert_redirected_to root_url
  end

  test 'should deny files#delete if not permissioned' do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_manage_files: false)
      sign_in(@restarone_user)

      delete comfy_admin_cms_site_file_url(subdomain: @restarone_subdomain.name, site_id: @site, id: @file)
    end

    assert_response :redirect
    expected_message = "You do not have the permission to do that. Only users who can_manage_files are allowed to perform that action."
    assert_match expected_message, request.flash[:alert]
    assert_redirected_to root_url
  end

end
