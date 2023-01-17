require "test_helper"

class ForumCategoriesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(global_admin: true, moderator: true)
    @subdomain = Subdomain.current
    @category = ForumCategory.create!(name: 'New Category', color: '#ffffff')
  end

  test "create# should successfully create and assign slug to forum category when slug is nill" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    sign_in(@user)

    assert_difference "ForumCategory.count", +1 do      
      post simple_discussion.create_forum_category_forum_threads_path, params: payload
    end

    assert_response :redirect
    assert_equal "Created!", flash[:notice] 
    assert_equal 'test-category', @controller.view_assigns['category'].slug
  end

  test "when forum is public: allows create forum-category if user is moderator" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @user.update(moderator: true)
    sign_in(@user)

    assert_difference "ForumCategory.count", +1 do      
      post simple_discussion.create_forum_category_forum_threads_path, params: payload
    end

    assert_response :redirect
    assert_equal "Created!", flash[:notice] 
    assert_equal 'test-category', @controller.view_assigns['category'].slug
  end

  test "when forum is public: denies create forum-category if user have access permission" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @user.update(moderator: false, can_access_forum: true)
    sign_in(@user)

    assert_no_difference "ForumCategory.count" do      
      post simple_discussion.create_forum_category_forum_threads_path, params: payload
    end

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end

  test "when forum is public: denies create forum-category if user has no permission" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @user.update(moderator: false, can_access_forum: false)
    sign_in(@user)

    assert_no_difference "ForumCategory.count" do      
      post simple_discussion.create_forum_category_forum_threads_path, params: payload
    end

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end

  test "when forum is private: allows create forum-category if user is moderator" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @subdomain.update(forum_is_private: true)

    @user.update(moderator: true)
    sign_in(@user)

    assert_difference "ForumCategory.count", +1 do      
      post simple_discussion.create_forum_category_forum_threads_path, params: payload
    end

    assert_response :redirect
    assert_equal "Created!", flash[:notice] 
    assert_equal 'test-category', @controller.view_assigns['category'].slug
  end

  test "when forum is private: denies create forum-category if user have access permission" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @subdomain.update(forum_is_private: true)

    @user.update(moderator: false, can_access_forum: true)
    sign_in(@user)

    assert_no_difference "ForumCategory.count" do      
      post simple_discussion.create_forum_category_forum_threads_path, params: payload
    end

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end

  test "when forum is private: denies create forum-category if user has no permission" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @subdomain.update(forum_is_private: true)

    @user.update(moderator: false, can_access_forum: false)
    sign_in(@user)

    assert_no_difference "ForumCategory.count" do      
      post simple_discussion.create_forum_category_forum_threads_path, params: payload
    end

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end

  test "when forum is public: allows update forum-category if user is moderator" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @user.update(moderator: true)
    sign_in(@user)
    
    patch simple_discussion.update_forum_category_forum_threads_path(id: @category.id), params: payload

    assert_response :redirect
    assert_equal "updated!", flash[:notice] 
    assert_equal 'test-category', @controller.view_assigns['category'].slug
  end

  test "when forum is public: denies update forum-category if user have access permission" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @user.update(moderator: false, can_access_forum: true)
    sign_in(@user)

    patch simple_discussion.update_forum_category_forum_threads_path(id: @category.id), params: payload

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end

  test "when forum is public: denies update forum-category if user has no permission" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @user.update(moderator: false, can_access_forum: false)
    sign_in(@user)

    patch simple_discussion.update_forum_category_forum_threads_path(id: @category.id), params: payload

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end

  test "when forum is private: allows update forum-category if user is moderator" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @subdomain.update(forum_is_private: true)

    @user.update(moderator: true)
    sign_in(@user)

    patch simple_discussion.update_forum_category_forum_threads_path(id: @category.id), params: payload

    assert_response :redirect
    assert_equal "updated!", flash[:notice] 
    assert_equal 'test-category', @controller.view_assigns['category'].slug
  end

  test "when forum is private: denies update forum-category if user have access permission" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @subdomain.update(forum_is_private: true)

    @user.update(moderator: false, can_access_forum: true)
    sign_in(@user)

    patch simple_discussion.update_forum_category_forum_threads_path(id: @category.id), params: payload

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end

  test "when forum is private: denies update forum-category if user has no permission" do
    payload = {
      forum_category: {
        name: 'Test category',
        color: '#000000'
      }
    }

    @subdomain.update(forum_is_private: true)

    @user.update(moderator: false, can_access_forum: false)
    sign_in(@user)

    patch simple_discussion.update_forum_category_forum_threads_path(id: @category.id), params: payload

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end

  test "when forum is public: allows delete forum-category if user is moderator" do
    @user.update(moderator: true)
    sign_in(@user)
    
    assert_difference "ForumCategory.count", -1 do 
      delete simple_discussion.destroy_forum_category_forum_threads_path(id: @category.id)
    end

    assert_response :redirect
    assert_equal "Destroyed!", flash[:notice] 
  end

  test "when forum is public: denies delete forum-category if user have access permission" do
    @user.update(moderator: false, can_access_forum: true)
    sign_in(@user)

    assert_no_difference "ForumCategory.count" do 
      delete simple_discussion.destroy_forum_category_forum_threads_path(id: @category.id)
    end

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end

  test "when forum is public: denies delete forum-category if user has no permission" do
    @user.update(moderator: false, can_access_forum: false)
    sign_in(@user)

    assert_no_difference "ForumCategory.count" do 
      delete simple_discussion.destroy_forum_category_forum_threads_path(id: @category.id)
    end

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end

  test "when forum is private: allows delete forum-category if user is moderator" do
    @subdomain.update(forum_is_private: true)

    @user.update(moderator: true)
    sign_in(@user)

    assert_difference "ForumCategory.count", -1 do 
      delete simple_discussion.destroy_forum_category_forum_threads_path(id: @category.id)
    end

    assert_response :redirect
    assert_equal "Destroyed!", flash[:notice] 
  end

  test "when forum is private: denies delete forum-category if user have access permission" do
    @subdomain.update(forum_is_private: true)

    @user.update(moderator: false, can_access_forum: true)
    sign_in(@user)

    assert_no_difference "ForumCategory.count" do 
      delete simple_discussion.destroy_forum_category_forum_threads_path(id: @category.id)
    end

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end

  test "when forum is private: denies delete forum-category if user has no permission" do
    @subdomain.update(forum_is_private: true)

    @user.update(moderator: false, can_access_forum: false)
    sign_in(@user)

    assert_no_difference "ForumCategory.count" do 
      delete simple_discussion.destroy_forum_category_forum_threads_path(id: @category.id)
    end

    assert_response :redirect
    assert_equal "You aren't allowed to do that.", flash[:alert]
  end
end