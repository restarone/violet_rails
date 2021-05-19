require "test_helper"

class SimpleDiscussion::ForumThreadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(global_admin: true)
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
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
end
