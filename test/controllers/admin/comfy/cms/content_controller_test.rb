require "test_helper"

class Comfy::Cms::ContentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @site = Comfy::Cms::Site.first
      @user = User.first
      refute @user.can_manage_web
      @layout = @site.layouts.last
      @page = @layout.pages.first
      @page.update(is_restricted: true)
    end
  end

  test "get root page" do
    get root_url
    assert_response :success
  end

  test "get root page (tracking enabled and cookies accepted)" do
    @restarone_subdomain.update!(tracking_enabled: true)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_difference "Ahoy::Event.count", +1 do
          perform_enqueued_jobs do
            get root_url(subdomain: @restarone_subdomain.name), headers: {"HTTP_COOKIE" => "cookies_accepted=true;"}
          end
      end
    end
  end

  test "get root page (tracking disabled)" do
    @restarone_subdomain.update!(tracking_enabled: false)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_no_difference "Ahoy::Event.count" do
          perform_enqueued_jobs do
            get root_url(subdomain: @restarone_subdomain.name)
          end
      end
    end
  end

  test "get root page (tracking disabled but cookies accepted)" do
    @restarone_subdomain.update!(tracking_enabled: false)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_no_difference "Ahoy::Event.count" do
          perform_enqueued_jobs do
            get root_url(subdomain: @restarone_subdomain.name), headers: {"HTTP_COOKIE" => "cookies_accepted=true;"}
          end
      end
    end
  end

  test "get root page (tracking enabled but cookies rejected)" do
    @restarone_subdomain.update!(tracking_enabled: true)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_no_difference "Ahoy::Event.count" do
          perform_enqueued_jobs do
            get root_url(subdomain: @restarone_subdomain.name), headers: {"HTTP_COOKIE" => "cookies_accepted=false;"}
          end
      end
    end
  end

  test "get root page (tracking enabled but cookies not consented)" do
    @restarone_subdomain.update!(tracking_enabled: true)
    Apartment::Tenant.switch @restarone_subdomain.name do
      assert_no_difference "Ahoy::Event.count" do
          perform_enqueued_jobs do
            get root_url(subdomain: @restarone_subdomain.name)
          end
      end
    end
  end

  test "deny restricted page (redirect to login)" do
    get root_url(subdomain: @restarone_subdomain.name)
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "deny restricted page (redirect to admin)" do
    refute @user.can_view_restricted_pages
    sign_in(@user)
    get root_url(subdomain: @restarone_subdomain.name)
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "allow restricted page (if permissioned)" do
    @user.update(can_view_restricted_pages: true)
    assert @user.can_view_restricted_pages
    sign_in(@user)
    get root_url(subdomain: @restarone_subdomain.name)
    assert_response :success
  end

  test "get root page with cookies_consent_ui rendering cms snippets of file" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @site = Comfy::Cms::Site.first
      file = @site.files.create(
        label:        "test",
        description:  "test file",
        file:         fixture_file_upload("fixture_image.png", "image/jpeg")
      )

      file_link_snippet = "{{ cms:file_link #{file.id} }}"
      file_image_tag = "{{ cms:file_link #{file.id}, as: image }}"

      @restarone_subdomain.update!(tracking_enabled: true, cookies_consent_ui: file_link_snippet + file_image_tag)
      @user.update(can_view_restricted_pages: true)

      sign_in(@user)
      perform_enqueued_jobs do
        get root_url(subdomain: @restarone_subdomain.name)

        # file_image_tag gets converted into img tag
        assert_select "#cookie-consent-wrapper img", { count: 1 }
        # cms:file_link snippets are not rendered as it is.
        assert_select "#cookie-consent-wrapper", { count: 0, text: file_link_snippet }
        assert_select "#cookie-consent-wrapper", { count: 0, text: file_image_tag }
      end
    end
  end
end
