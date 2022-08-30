require "test_helper"

class Comfy::Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    @user = users(:public)
    @public_subdomain = subdomains(:public)
    @domain = @user.subdomain
    @user.update(can_manage_users: true, can_manage_email: true)

    @restarone_subdomain = Subdomain.find_by(name: 'restarone')

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
      @restarone_user.update(can_manage_users: true, can_access_admin: true)

      @other_user = User.create!(email: 'contact1@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)
    end
  end

  test "get #index by authorized personnel" do
    sign_in(@user)
    get admin_users_url(subdomain: @domain)
    assert_response :success
    assert_template :index
    assert response.body.include? I18n.t('views.comfy.users.index.header.title')
    assert response.body.include? I18n.t('views.comfy.users.index.header.action')
  end

  test "#index: users table with all necessary columns is rendered" do
    column_headings = [
      "Email",
      "Name",
      "Can manage web",
      "Can manage analytics",
      "Can manage files",
      "Can manage email",
      "Can manage users",
      "Can manage blog",
      "Can manage api",
      "Can manage app settings",
      "Can view restricted pages",
      "Can manage forum",
      "Current sign in at",
      "Last sign in at"
    ]
    sign_in(@user)
    get admin_users_url(subdomain: @domain)
    assert_select "table", 1, "This page must contain a users table"
    column_headings.each do |heading|
      assert_select "thead th", {count: 1, text: heading}, "Users table must contain '#{heading}' column"
    end
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
    @user.update(can_manage_users: false)
    sign_in(@user)
    get new_admin_user_url(subdomain: @domain)
    assert_response :redirect
    assert flash.alert
  end

  test "#edit" do
    sign_in(@user)
    get edit_admin_user_url(subdomain: @domain, id: @user.id)
    assert_response :success
  end

  test "#edit: show forum button if selected " do
    sign_in(@user)
    @public_subdomain.update(forum_enabled: true)
    get mailbox_path
    assert_select 'a', {count: 1, text: 'Forum'}
  end

  test "#edit: show blog button if selected " do
    sign_in(@user)
    @public_subdomain.update(blog_enabled: true)
    get mailbox_path
    assert_select 'a', {count: 1, text: 'Blog'}
  end
  
  test "#edit: hide forum button if unselected " do
    sign_in(@user)
    @public_subdomain.update(forum_enabled: false)
    get mailbox_path
    assert_select 'a', {count: 0, text:'Forum'}
  end
  
  test "#edit: hide blog button if unselected " do
    sign_in(@user)
    @public_subdomain.update(blog_enabled: false)
    get mailbox_path
    assert_select 'a', {count: 0, text:'Blog'}
  end

  test "denies #edit if not permissioned" do
    @user.update(can_manage_users: false)
    sign_in(@user)
    get edit_admin_user_url(subdomain: @domain, id: @user.id)
    assert_response :redirect
    assert flash.alert
  end

  test "#edit: shows session details if the logged-in user can_manage_analytics" do
    @user.update(can_manage_analytics: true)
    sign_in(@user)
    get edit_admin_user_url(subdomain: @domain, id: @user.id)
    assert_response :success
    assert_select 'h3', {count: 1, text: 'Sessions'}, 'This page must contain Sessions details.'
  end

  test "#edit: does not show session details if the logged-in user can_manage_analytics permission is false" do
    @user.update(can_manage_analytics: false)
    sign_in(@user)
    get edit_admin_user_url(subdomain: @domain, id: @user.id)
    assert_response :success
    assert_select 'h3', {count: 0, text: 'Sessions'}, 'This page must not contain Sessions details.'
  end

  test "#update" do
    sign_in(@user)
    @user.update(can_manage_users: true)
    payload = {
      user: {
        name: 'foobar'
      }
    }
    assert_changes "@user.reload.name" do
      patch admin_user_url(subdomain: @domain, id: @user.id), params: payload
      assert flash.notice
      refute flash.alert
      assert_redirected_to admin_users_url(subdomain: @domain)
    end
  end

  test "denies #update if not permissioned" do
    @user.update(can_manage_users: false)
    sign_in(@user)
    payload = {
      user: {
        can_manage_users: 1
      }
    }
    assert_no_changes "@user.reload.can_manage_users" do
      patch admin_user_url(subdomain: @domain, id: @user.id), params: payload
      assert flash.alert
      assert_response :redirect
    end
  end

  test 'tracks user update (if tracking is enabled)' do
    @restarone_subdomain.update(tracking_enabled: true)

    Apartment::Tenant.switch @restarone_subdomain.name do
      sign_in(@restarone_user)
      payload = {
        user: {
          name: 'foobar'
        }
      }

      assert_difference "Ahoy::Event.count", +1 do
        patch admin_user_url(subdomain: @restarone_subdomain.name, id: @other_user.id), params: payload
      end

    end
    assert_response :redirect
    assert_redirected_to admin_users_url(subdomain: @restarone_subdomain.name)
  end

  test 'does not track user update (if tracking is disabled)' do
    @restarone_subdomain.update(tracking_enabled: false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      sign_in(@restarone_user)
      payload = {
        user: {
          name: 'foobar'
        }
      }

      assert_no_difference "Ahoy::Event.count", +1 do
        patch admin_user_url(subdomain: @restarone_subdomain.name, id: @other_user.id), params: payload
      end

    end
    assert_response :redirect
    assert_redirected_to admin_users_url(subdomain: @restarone_subdomain.name)
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
    @user.update(can_manage_users: false)
    sign_in(@user)
    payload = {
      user: {
        email: 'testemail@tester.com'
      }
    }
    assert_no_difference "User.all.size" do
      post invite_admin_users_url(subdomain: @domain, params: payload)
      assert flash.alert
      assert_response :redirect
    end
  end

  test "#destroy" do
    assert_difference "User.all.size", -1 do
      sign_in(@user)
      delete admin_user_url(subdomain: @domain, id: users(:one).id)
      assert flash.notice
      refute flash.alert
      assert_redirected_to admin_users_url(subdomain: @domain)
    end
  end

  test "denies #destroy if not permissioned" do
    @user.update(can_manage_users: false)
    assert_no_difference "User.all.size" do
      sign_in(@user)
      delete admin_user_url(subdomain: @domain, id: @user.id)
      refute flash.notice
      assert flash.alert
      assert_response :redirect
    end
  end

  test "allow #destroy when user has forum-thread, forum-posts and forum-subscription" do
    test_user = users(:one)
    forum_category = ForumCategory.create!(name: 'test', slug: 'test')
    
    forum_thread = test_user.forum_threads.create!(title: 'Test Thread 1', forum_category_id: forum_category.id)
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: test_user.id, body: 'test body 1')
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: test_user.id, body: 'test body 2')
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: test_user.id, body: 'test body 3')
    ForumSubscription.create!(forum_thread_id: forum_thread.id, user_id: test_user.id, subscription_type: 'optin')

    subscriptions_count = test_user.forum_subscriptions.count

    sign_in(@user)

    assert_difference "User.count", -1 do
      assert_no_difference "ForumThread.count" do
        assert_no_difference "ForumPost.count" do
          # Only forum-subscriptions are deleted
          assert_difference "ForumSubscription.count", -subscriptions_count do
            delete admin_user_url(subdomain: @domain, id: test_user.id)
          end
        end
      end
    end

    assert flash.notice
    refute flash.alert
    assert_redirected_to admin_users_url(subdomain: @domain)
  end

  test "allow #destroy when user has forum-subscriptions, forum-thread with posts in which other-user has posted too" do
    test_user = users(:one)
    forum_category = ForumCategory.create!(name: 'test', slug: 'test')
    
    forum_thread = test_user.forum_threads.create!(title: 'Test Thread 1', forum_category_id: forum_category.id)
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: test_user.id, body: 'test body 1')
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: @user.id, body: 'test body 2')
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: @user.id, body: 'test body 3')
    ForumSubscription.create!(forum_thread_id: forum_thread.id, user_id: test_user.id, subscription_type: 'optin')
    ForumSubscription.create!(forum_thread_id: forum_thread.id, user_id: @user.id, subscription_type: 'optin')

    # Only subscriptions of the user that is to be deleted
    subscriptions_count = test_user.forum_subscriptions.count

    sign_in(@user)

    assert_difference "User.count", -1 do
      assert_no_difference "ForumThread.count" do
        assert_no_difference "ForumPost.count" do
          # Deleted user's subscriptions are only deleted
          assert_difference "ForumSubscription.count", -subscriptions_count do
            delete admin_user_url(subdomain: @domain, id: test_user.id)
          end
        end
      end
    end

    assert flash.notice
    refute flash.alert
    assert_redirected_to admin_users_url(subdomain: @domain)
  end

  test "allow #destroy when user has forum-subscriptions, forum-posts of other user's forum-thread" do
    test_user = users(:one)
    forum_category = ForumCategory.create!(name: 'test', slug: 'test')
    
    forum_thread = @user.forum_threads.create!(title: 'Test Thread 1', forum_category_id: forum_category.id)
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: @user.id, body: 'test body 1')
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: test_user.id, body: 'test body 2')
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: test_user.id, body: 'test body 3')
    ForumSubscription.create!(forum_thread_id: forum_thread.id, user_id: test_user.id, subscription_type: 'optin')
    ForumSubscription.create!(forum_thread_id: forum_thread.id, user_id: @user.id, subscription_type: 'optin')

    subscriptions_count = test_user.forum_subscriptions.count

    sign_in(@user)

    assert_difference "User.count", -1 do
      assert_no_difference "ForumThread.count" do
        assert_no_difference "ForumPost.count" do
          # Deletes only tes-user's forum-subscriptions
          assert_difference "ForumSubscription.count", -subscriptions_count do
            delete admin_user_url(subdomain: @domain, id: test_user.id)
          end
        end
      end
    end

    assert flash.notice
    refute flash.alert
    assert_redirected_to admin_users_url(subdomain: @domain)
  end

  test "#index: shows on the users with provided categories" do
    category = comfy_cms_categories(:user_1)
    @user.update!(category_ids: [category.id])

    sign_in(@user)
    get admin_users_url(subdomain: @domain), params: {categories: category.label}
    assert_response :success

    categorized_user_ids = [@user.id]
    @controller.view_assigns['users'].each do |user|
      assert_includes categorized_user_ids, user.id
    end
  end
end
