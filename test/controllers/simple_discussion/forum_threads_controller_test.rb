require "test_helper"

class SimpleDiscussion::ForumThreadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    Apartment::Tenant.switch 'public' do
      @other_user = User.create!(email: 'contact1@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)
    end
    @user.update(global_admin: true)
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
    @forum_category = ForumCategory.create!(name: 'test', slug: 'test')
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
        end
      end
    end
    assert_response :redirect
    assert_redirected_to simple_discussion.forum_thread_path(id: ForumThread.last.slug)
  end

  test 'notifies mods when thread is created' do
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
        end
      end
    end
    assert_response :redirect
    assert_redirected_to simple_discussion.forum_thread_path(id: ForumThread.last.slug)
  end
end
