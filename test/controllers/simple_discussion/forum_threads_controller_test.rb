require "test_helper"

class SimpleDiscussion::ForumThreadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @other_user = User.create!(email: 'contact1@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)

    @user.update(global_admin: true)
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
    @forum_category = ForumCategory.create!(name: 'test', slug: 'test')
    Sidekiq::Testing.fake!
  end

  test 'denies #index if forum is disabled' do
    @restarone_subdomain.update(forum_enabled: false)
    get simple_discussion.root_url(subdomain: @restarone_subdomain.name)
    assert_response :redirect
  end

  test 'denies #index if forum is by registration' do
    @restarone_subdomain.update(forum_is_private: true)
    get simple_discussion.root_url(subdomain: @restarone_subdomain.name)
    assert_response :redirect
  end

  test 'allows #index if forum is by registration' do
    sign_in(@restarone_user)
    @restarone_subdomain.update(forum_is_private: true)
    get simple_discussion.root_url(subdomain: @restarone_subdomain.name)
    assert_response :success
  end

  test 'allows #index if not logged in' do
    get simple_discussion.root_url(subdomain: @restarone_subdomain.name)
    assert_response :success
  end

  test 'disallows forum_threads#new if not logged in' do
    get simple_discussion.new_forum_thread_url(subdomain: @restarone_subdomain.name)
    assert_response :redirect
    assert_redirected_to new_user_session_url(subdomain: @restarone_subdomain.name)
  end

  test 'allows forum_threads#new if logged in' do
    sign_in(@restarone_user)
    get simple_discussion.new_forum_thread_url(subdomain: @restarone_subdomain.name)
    assert_template :new
    assert_response :success
  end

  test 'denies new thread creation if not logged in' do
    payload = {
      forum_thread: {
        title: 'foo',
        forum_category_id: @forum_category.id,
        forum_posts_attributes: {
          body: 'bar'
        }
      }
    }
    assert_no_difference "ForumThread.all.size" do
      post simple_discussion.forum_threads_url, params: payload
      Sidekiq::Worker.drain_all
    end
      assert_response :redirect
      assert_redirected_to new_user_session_path
  end

  test 'allows new thread creation if logged in (mod does not get emails for thread creation)' do
    sign_in(@user)
    payload = {
      forum_thread: {
        forum_category_id: @forum_category.id,
        title: 'foo',
        forum_posts_attributes: {
          "0": {
            body: 'bar'
          }
        }
      }
    }
    assert_difference "ForumThread.all.size", +1 do
      perform_enqueued_jobs do
        assert_no_changes "SimpleDiscussion::UserMailer.deliveries.size" do
          post simple_discussion.forum_threads_url, params: payload
          Sidekiq::Worker.drain_all
        end
      end
    end
    assert_response :redirect
    assert_redirected_to simple_discussion.forum_thread_path(id: ForumThread.last.slug)
  end

  test 'notifies mods when thread/reply is created' do
    # stub subscribed users so the notification email gets enqueued
    ForumThread.any_instance.stubs(:subscribed_users).returns(User.all)
    assert @user.update(moderator: true)
    sign_in(@other_user)
    payload = {
      forum_thread: {
        forum_category_id: @forum_category.id,
        title: 'foo',
        forum_posts_attributes: {
          "0": {
            body: 'bar'
          }
        }
      }
    }
    assert_difference "ForumThread.all.size", +1 do
      perform_enqueued_jobs do
        assert_changes "SimpleDiscussion::UserMailer.deliveries.size" do
          post simple_discussion.forum_threads_url, params: payload
          Sidekiq::Worker.drain_all
        end
      end
    end
    assert_response :redirect
    assert_redirected_to simple_discussion.forum_thread_path(id: ForumThread.last.slug)

    assert_difference "ForumPost.count" do
      perform_enqueued_jobs do
        assert_changes "SimpleDiscussion::UserMailer.deliveries.size" do
          post simple_discussion.forum_thread_forum_posts_path(ForumThread.last), params: {
            forum_post: {
              body: "Reply"
            }
          }
          Sidekiq::Worker.drain_all
        end
      end
    end
  end

  test 'allows new thread creation and tracks if plugin: subdomain/subdomain_events is enabled' do
    subdomains(:public).update(api_plugin_events_enabled: true)
    sign_in(@user)
    payload = {
      forum_thread: {
        forum_category_id: @forum_category.id,
        title: 'foo',
        forum_posts_attributes: {
          "0": {
            body: 'bar'
          }
        }
      }
    }
    assert_difference "ApiResource.count", +1 do
      post simple_discussion.forum_threads_url, params: payload
      Sidekiq::Worker.drain_all
    end
  end

  test 'tracks new thread/reply creation if plugin: subdomain/subdomain_events is enabled' do
    subdomains(:public).update(api_plugin_events_enabled: true)
    sign_in(@user)
    payload = {
      forum_thread: {
        forum_category_id: @forum_category.id,
        title: 'foo',
        forum_posts_attributes: {
          "0": {
            body: 'bar'
          }
        }
      }
    }
    post simple_discussion.forum_threads_url, params: payload
    assert_difference "ApiResource.count", +2 do
      post simple_discussion.forum_thread_forum_posts_path(ForumThread.last), params: {
        forum_post: {
          body: "Reply"
        }
      }
      Sidekiq::Worker.drain_all
    end
  end

  test 'tracks forum-thread view (if tracking is enabled)' do
    @restarone_subdomain.update(tracking_enabled: true)

    Apartment::Tenant.switch @restarone_subdomain.name do
      forum_category = ForumCategory.create!(name: 'test', slug: 'test')
      forum_thread = @restarone_user.forum_threads.new(title: 'Test Thread', forum_category_id: forum_category.id)
      forum_thread.save!
      forum_post = ForumPost.create!(forum_thread_id: forum_thread.id, user_id: @restarone_user.id, body: 'test body')


      sign_in(@restarone_user)

      assert_difference "Ahoy::Event.count", +1 do
        get simple_discussion.forum_thread_url(subdomain: @restarone_subdomain.name, id: forum_thread.slug)
      end

    end
    assert_response :success
  end

  test 'does not track forum-thread view (if tracking is disabled)' do
    @restarone_subdomain.update(tracking_enabled: false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      forum_category = ForumCategory.create!(name: 'test', slug: 'test')
      forum_thread = @restarone_user.forum_threads.new(title: 'Test Thread', forum_category_id: forum_category.id)
      forum_thread.save!
      forum_post = ForumPost.create!(forum_thread_id: forum_thread.id, user_id: @restarone_user.id, body: 'test body')


      sign_in(@restarone_user)

      assert_no_difference "Ahoy::Event.count", +1 do
        get simple_discussion.forum_thread_url(subdomain: @restarone_subdomain.name, id: forum_thread.slug)
      end

    end
    assert_response :success
  end
end
