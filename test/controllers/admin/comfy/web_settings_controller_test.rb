require "test_helper"

class Comfy::Admin::WebSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @domain = @user.subdomain
  end

  test "get #edit by authorized personnel" do
    sign_in(@user)
    @user.update(can_manage_web: true)
    get edit_web_settings_url(subdomain: @domain)
    assert_response :success
    assert_template :edit
  end

  test "denies #edit if not permissioned" do
    sign_in(@user)
    @user.update(can_manage_web: false)
    get edit_web_settings_url(subdomain: @domain)
    assert_response :redirect
    assert flash.alert
  end

  test "#denies #update if not permissioned" do
    sign_in(@user)
    @user.update(can_manage_web: false)
    payload = {
    }
    patch web_settings_url(subdomain: @domain, id: @user.id), params: payload
    assert_response :redirect
  end

  test "#update if permissioned" do
    sign_in(@user)
    @user.update(can_manage_web: true)
    payload = {
      subdomain: {
        html_title: 'foo',
        blog_title: 'bar',
        blog_html_title: 'baz',
        forum_title: 'quux',
        forum_html_title: 'www'
      }
    }
    assert_changes "Subdomain.current.html_title" do
      patch web_settings_url(subdomain: @domain, id: @user.id), params: payload
      assert_response :redirect
    end
  end
end
