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

  test "#index: indicates the thread's author has been deleted if the user was deleted"do
    Apartment::Tenant.switch @restarone_subdomain.name do
      test_user = User.create!(email: 'test@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)
      forum_category = ForumCategory.create!(name: 'test', slug: 'test')
    
      forum_thread_1 = test_user.forum_threads.create!(title: 'Test Thread 1', forum_category_id: forum_category.id)
      ForumPost.create!(forum_thread_id: forum_thread_1.id, user_id: test_user.id, body: 'test body 1')
    
      forum_thread_2 = @restarone_user.forum_threads.create!(title: 'Test Thread 2', forum_category_id: forum_category.id)
      ForumPost.create!(forum_thread_id: forum_thread_2.id, user_id: @restarone_user.id, body: 'test body 4')

      # Deleting the test_user
      test_user.destroy!

      sign_in(@restarone_user)
      get simple_discussion.root_url(subdomain: @restarone_subdomain.name)
      
      assert_response :success

      # Shows 'author deleted' for forum-thread whose author has been deleted
      assert_select '.card-body .forum-thread .row .col', html: /Test Thread 1/ do
        assert_select '.thread-details', html: /(author deleted)/
      end

      # Does not show 'author deleted' for forum-thread whose author has not been deleted
      assert_select '.card-body .forum-thread .row .col', html: /Test Thread 2/ do
        assert_select '.thread-details', { count: 0, html: /(author deleted)/ }
      end
    end
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

  test '#index: shows the latest post.body in the thread preview' do
    Apartment::Tenant.switch @restarone_subdomain.name do
      forum_category = ForumCategory.create!(name: 'test', slug: 'test')
    
      forum_thread_1 = @restarone_user.forum_threads.create!(title: 'Test Thread 1', forum_category_id: forum_category.id)
      ForumPost.create!(forum_thread_id: forum_thread_1.id, user_id: @restarone_user.id, body: 'test body 1')
      ForumPost.create!(forum_thread_id: forum_thread_1.id, user_id: @restarone_user.id, body: 'test body 2')
      ForumPost.create!(forum_thread_id: forum_thread_1.id, user_id: @restarone_user.id, body: 'test body 3')
    
      forum_thread_2 = @restarone_user.forum_threads.create!(title: 'Test Thread 2', forum_category_id: forum_category.id)
      ForumPost.create!(forum_thread_id: forum_thread_2.id, user_id: @restarone_user.id, body: 'test body 4')
      forum_post = ForumPost.create!(forum_thread_id: forum_thread_2.id, user_id: @restarone_user.id, body: 'test body 5')
      ForumPost.create!(forum_thread_id: forum_thread_2.id, user_id: @restarone_user.id, body: 'test body 6')
      forum_post.update!(body: 'test body 5 updated')

      sign_in(@restarone_user)
      get simple_discussion.root_url(subdomain: @restarone_subdomain.name)
      
      assert_response :success

      # Middle forum-post was updated in the end for forum_thread_2 which should be shown in the thread preview.
      assert_select '.card-body .forum-thread .row .col', html: /Test Thread 2/ do
        assert_select 'p.text-muted', text: /test body 5 updated/
      end

      # If no middle forum-post was updated in the end, then the last created/updated forum-post should be shown in the thread preview for forum_thread_1.
      assert_select '.card-body .forum-thread .row .col', html: /Test Thread 1/ do
        assert_select 'p.text-muted', text: /test body 3/
      end
    end
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

    # Validation errors are not present in the response-body
    assert_select 'div#error_explanation', { count: 0 }
    refute @controller.view_assigns['forum_thread'].errors.present?
  end

  test 'denies new thread creation with validation errors in response if invalid payload is provided' do
    subdomains(:public).update(api_plugin_events_enabled: true)
    sign_in(@user)
    payload = {
      forum_thread: {
        forum_category_id: '',
        title: '',
        forum_posts_attributes: {
          "0": {
            body: ''
          }
        }
      }
    }
    assert_no_difference "ApiResource.count" do
      post simple_discussion.forum_threads_url, params: payload
      Sidekiq::Worker.drain_all
    end

    assert_response :unprocessable_entity
    # Validation errors are present in the response-body
    assert_select 'div#error_explanation'
    assert @controller.view_assigns['forum_thread'].errors.present?
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

    assert_difference "ApiResource.count", +2 do
      post simple_discussion.forum_threads_url, params: payload
      post simple_discussion.forum_thread_forum_posts_path(ForumThread.last), params: {
        forum_post: {
          body: "Reply"
        }
      }
    end
  end

  test 'denies new thread/reply creation with validation-errors in response' do
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
    post simple_discussion.forum_thread_forum_posts_path(ForumThread.last), params: {
      forum_post: {
        body: ""
      }
    }
    Sidekiq::Worker.drain_all

    assert_response :unprocessable_entity
    # Validation errors are present in the response-body
    assert_select 'div#error_explanation'
    assert @controller.view_assigns['forum_post'].errors.present?
  end

  test 'tracks forum-thread view (if tracking is enabled and cookies accepted)' do
    @restarone_subdomain.update(tracking_enabled: true)

    Apartment::Tenant.switch @restarone_subdomain.name do
      forum_category = ForumCategory.create!(name: 'test', slug: 'test')
      forum_thread = @restarone_user.forum_threads.new(title: 'Test Thread', forum_category_id: forum_category.id)
      forum_thread.save!
      forum_post = ForumPost.create!(forum_thread_id: forum_thread.id, user_id: @restarone_user.id, body: 'test body')


      sign_in(@restarone_user)

      assert_difference "Ahoy::Event.count", +1 do
        get simple_discussion.forum_thread_url(subdomain: @restarone_subdomain.name, id: forum_thread.slug), headers: {"HTTP_COOKIE" => "cookies_accepted=true;"}
      end

    end
    assert_response :success
  end

  test 'does not track forum-thread view (if tracking is enabled and cookies not accepted)' do
    @restarone_subdomain.update(tracking_enabled: false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      forum_category = ForumCategory.create!(name: 'test', slug: 'test')
      forum_thread = @restarone_user.forum_threads.new(title: 'Test Thread', forum_category_id: forum_category.id)
      forum_thread.save!
      forum_post = ForumPost.create!(forum_thread_id: forum_thread.id, user_id: @restarone_user.id, body: 'test body')


      sign_in(@restarone_user)

      assert_no_difference "Ahoy::Event.count", +1 do
        get simple_discussion.forum_thread_url(subdomain: @restarone_subdomain.name, id: forum_thread.slug), headers: {"HTTP_COOKIE" => "cookies_accepted=false;"}
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

  test "#show: indicates the thread's author and the respective forum-posts has been deleted if the user was deleted"do
    Apartment::Tenant.switch @restarone_subdomain.name do
      test_user = User.create!(email: 'test@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)
      forum_category = ForumCategory.create!(name: 'test', slug: 'test')
    
      forum_thread_1 = test_user.forum_threads.create!(title: 'Test Thread 1', forum_category_id: forum_category.id)
      forum_post_1 = ForumPost.create!(forum_thread_id: forum_thread_1.id, user_id: test_user.id, body: 'test body 1')
      forum_post_2 = ForumPost.create!(forum_thread_id: forum_thread_1.id, user_id: @restarone_user.id, body: 'test body 2')
    
      # Deleting the test_user
      test_user.destroy!

      sign_in(@restarone_user)
      get simple_discussion.forum_thread_url(subdomain: @restarone_subdomain.name, id: forum_thread_1.slug)
      
      assert_response :success

      # Shows 'author deleted' for forum-thread whose author has been deleted
      assert_select '.card-body .row', html: /Test Thread 1/
      assert_select '.card-body .thread-details', html: /(author deleted)/
      
      # Shows 'User deleted' for forum-post whose user has been deleted
      assert_select "#forum_post_#{forum_post_1.id}", html: /User deleted/
      # Does not show 'User deleted' for forum-post whose user has not been deleted
      assert_select "#forum_post_#{forum_post_2.id}", { count: 0, html: /User deleted/ }
    end
  end

  test "#show: indicates only the respective forum-posts has been deleted if the user was deleted but not the forum-thread(created by another user)" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      test_user = User.create!(email: 'test@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)
      forum_category = ForumCategory.create!(name: 'test', slug: 'test')
    
      forum_thread_1 = @restarone_user.forum_threads.create!(title: 'Test Thread 1', forum_category_id: forum_category.id)
      forum_post_1 = ForumPost.create!(forum_thread_id: forum_thread_1.id, user_id: @restarone_user.id, body: 'test body 4')
      forum_post_2 = ForumPost.create!(forum_thread_id: forum_thread_1.id, user_id: test_user.id, body: 'test body 5')

      # Deleting the test_user
      test_user.destroy!

      sign_in(@restarone_user)
      get simple_discussion.forum_thread_url(subdomain: @restarone_subdomain.name, id: forum_thread_1.slug)
      
      assert_response :success

      # Does not show 'author deleted' for forum-thread whose author has not been deleted
      assert_select '.card-body .row', html: /Test Thread 1/
      assert_select '.card-body .thread-details', { count: 0, html: /(author deleted)/ }
      
      # Does not show 'User deleted' for forum-post whose user has not been deleted
      assert_select "#forum_post_#{forum_post_1.id}", { count: 0, html: /User deleted/ }
      # Shows 'User deleted' for forum-post whose user has been deleted
      assert_select "#forum_post_#{forum_post_2.id}", html: /User deleted/
    end
  end

  test 'denies forum-thread update with validation errors in response if invalid payload is provided' do
    forum_thread = @user.forum_threads.create!(title: 'Test Thread 1', forum_category_id: @forum_category.id)
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: @user.id, body: 'test body 1')
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: @user.id, body: 'test body 2')
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: @user.id, body: 'test body 3')
  
    sign_in(@user)
    payload = {
      forum_thread: {
        forum_category_id: '',
        title: '',
        forum_posts_attributes: {
          "0": {
            body: ''
          }
        }
      }
    }

    patch simple_discussion.forum_thread_url(id: forum_thread.id), params: payload
    Sidekiq::Worker.drain_all

    assert_response :unprocessable_entity
    # Validation errors are present in the response-body
    assert_select 'div#error_explanation'
    assert @controller.view_assigns['forum_thread'].errors.present?
  end

  test 'allows forum-thread update without validation errors in response' do
    forum_thread = @user.forum_threads.create!(title: 'Test Thread 1', forum_category_id: @forum_category.id)
    ForumPost.create!(forum_thread_id: forum_thread.id, user_id: @user.id, body: 'test body 1')
  
    sign_in(@user)
    payload = {
      forum_thread: {
        title: 'Title Changed'
      }
    }

    patch simple_discussion.forum_thread_url(id: forum_thread.id), params: payload
    Sidekiq::Worker.drain_all

    assert_response :redirect
    # Validation errors are not present in the response-body
    assert_select 'div#error_explanation', { count: 0 }
    refute @controller.view_assigns['forum_thread'].errors.present?

    assert_equal payload[:forum_thread][:title], forum_thread.reload.title
  end

  test 'send notification to mentioned users in thread/post body' do
    sign_in(@other_user)
    payload = {
      forum_thread: {
        forum_category_id: @forum_category.id,
        title: 'Test Mentioned User',
        forum_posts_attributes: {
          "0": {
            body: ActionText::TrixAttachment.from_attributes({ "sgid" => @user.attachable_sgid})
          }
        }
      }
    }
    assert_difference "ForumThread.all.size", +1 do
      perform_enqueued_jobs do
        assert_changes "SimpleDiscussion::UserMailer.deliveries.size", +1 do
          post simple_discussion.forum_threads_url, params: payload
          Sidekiq::Worker.drain_all
        end
      end
    end
    assert_equal SimpleDiscussion::UserMailer.deliveries.last.to, [@user.email]
    assert_equal SimpleDiscussion::UserMailer.deliveries.last.subject, payload[:forum_thread][:title]

    assert_response :redirect
    assert_redirected_to simple_discussion.forum_thread_path(id: ForumThread.last.slug)

    assert_difference "ForumPost.count", +1 do
      perform_enqueued_jobs do
        assert_changes "SimpleDiscussion::UserMailer.deliveries.size", +1 do
          post simple_discussion.forum_thread_forum_posts_path(ForumThread.last), params: {
            forum_post: {
              body: ActionText::TrixAttachment.from_attributes({ "sgid" => @user.attachable_sgid })
            }
          }
          Sidekiq::Worker.drain_all
        end
      end
    end
    assert_equal SimpleDiscussion::UserMailer.deliveries.last.to, [@user.email]
    assert_equal SimpleDiscussion::UserMailer.deliveries.last.subject, "New post in #{payload[:forum_thread][:title]}"
  end
end