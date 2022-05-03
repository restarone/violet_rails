# frozen_string_literal: true

require "test_helper"

class SimpleDiscussion::ForumPostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @current_subdomain_name = 'public'
    @user.update(global_admin: true)

		@restarone_subdomain = Subdomain.find_by(name: 'restarone')

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
      @forum_category = ForumCategory.create!(name: 'test', slug: 'test')
      @forum_thread = @restarone_user.forum_threads.new(title: 'Test Thread', forum_category_id: @forum_category.id)
      @forum_thread.save!
      @forum_post = ForumPost.create!(forum_thread_id: @forum_thread.id, user_id: @restarone_user.id, body: 'test body')
    end
  end

	test 'tracks forum-post update (if tracking is enabled)' do
    @restarone_subdomain.update(tracking_enabled: true)

    Apartment::Tenant.switch @restarone_subdomain.name do
      sign_in(@restarone_user)
      payload = {
        forum_post: {
          body: 'foobar'
        }
      }

      assert_difference "Ahoy::Event.count", +1 do
        patch simple_discussion.forum_thread_forum_post_url(subdomain: @restarone_subdomain.name, forum_thread_id: @forum_thread.id, id: @forum_post.id), params: payload
      end

    end
    assert_response :redirect
    assert_redirected_to simple_discussion.forum_thread_url(subdomain: @restarone_subdomain.name, id: @forum_thread.slug)
  end

	test 'does not track forum-post update (if tracking is disabled)' do
    @restarone_subdomain.update(tracking_enabled: false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      sign_in(@restarone_user)
      payload = {
        forum_post: {
          body: 'foobar'
        }
      }

      assert_no_difference "Ahoy::Event.count", +1 do
        patch simple_discussion.forum_thread_forum_post_url(subdomain: @restarone_subdomain.name, forum_thread_id: @forum_thread.id, id: @forum_post.id), params: payload
      end

    end
    assert_response :redirect
    assert_redirected_to simple_discussion.forum_thread_url(subdomain: @restarone_subdomain.name, id: @forum_thread.slug)
  end


end
