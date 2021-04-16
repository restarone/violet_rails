require "test_helper"



class Comfy::Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    @user = users(:public)
    @domain = @user.subdomain
  end

  test "get #index by authorized personnel" do
    sign_in(@user)
    get admin_users_url(subdomain: @domain)
    assert_response :success
    assert_template :index
    assert response.body.include? I18n.t('views.comfy.users.index.header.title')
    assert response.body.include? I18n.t('views.comfy.users.index.header.action')
  end

  test "deny #index" do
    get admin_users_url(subdomain: @domain)
    assert_response :redirect
  end

  test "#new" do
    sign_in(@user)
    get new_admin_user_url(subdomain: @domain)
    assert_response :success
  end

  test "denies #new if not permissioned" do
    skip('implement soon, with granular permissions')
    sign_in(@user)
    get new_admin_user_url(subdomain: @domain)
    assert_response :success
  end

  test "#edit" do
    sign_in(@user)
    get edit_admin_user_url(subdomain: @domain, id: @user.id)
    assert_response :success
  end

  test "denies #edit if not permissioned" do
    skip('implement soon, with granular permissions')
    sign_in(@user)
    get edit_admin_user_url(subdomain: @domain, id: @user.id)
    assert_response :success
  end

  test "#update" do
    sign_in(@user)
    payload = {
      user: {
        can_manage_users: 1
      }
    }
    assert_changes "@user.reload.can_manage_users" do      
      patch admin_user_url(subdomain: @domain, id: @user.id), params: payload
      assert flash.notice
      refute flash.alert
      assert_redirected_to admin_users_url(subdomain: @domain)
    end
  end

  test "denies #update if not permissioned" do
    skip('implement soon, with granular permissions')
    sign_in(@user)
    payload = {
      user: {
        can_manage_users: 1
      }
    }
    assert_changes "@user.reload.can_manage_users" do      
      patch admin_user_url(subdomain: @domain, id: @user.id), params: payload
      assert flash.notice
      refute flash.alert
      assert_redirected_to admin_users_url(subdomain: @domain)
    end
  end

  test "#invite" do
    sign_in(@user)
    payload = {
      user: {
        email: 'testemail@tester.com'
      }
    }
    assert_difference "User.all.size", +1 do      
      post invite_admin_users_url(subdomain: @domain, params: payload)
      assert_redirected_to admin_users_url(subdomain: @domain)
    end
  end

  test "denies #invite if not permissioned" do
    skip('implement soon, with granular permissions')
    sign_in(@user)
    payload = {
      user: {
        email: 'testemail@tester.com'
      }
    }
    assert_difference "User.all.size", +1 do      
      post invite_admin_users_url(subdomain: @domain, params: payload)
      assert_redirected_to admin_users_url(subdomain: @domain)
    end
  end

  test "#destroy" do
    assert_difference "User.all.size", -1 do
      sign_in(@user)
      delete admin_user_url(subdomain: @domain, id: @user.id)
      assert flash.notice
      refute flash.alert
      assert_redirected_to admin_users_url(subdomain: @domain)
    end
  end

  test "denies #destroy if not permissioned" do
    skip('implement soon, with granular permissions')
    assert_difference "User.all.size", -1 do
      sign_in(@user)
      delete admin_user_url(subdomain: @domain, id: @user.id)
      assert flash.notice
      refute flash.alert
      assert_redirected_to admin_users_url(subdomain: @domain)
    end
  end
end
