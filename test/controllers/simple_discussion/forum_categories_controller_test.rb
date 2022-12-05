require "test_helper"

class ForumCategoriesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(global_admin: true, moderator: true)
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

end