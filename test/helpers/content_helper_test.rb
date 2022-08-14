require 'test_helper'

class ContentHelperTest < ActionView::TestCase
  include Comfy::CmsHelper

  setup do
    @user = users(:public)
    @snippet = comfy_cms_snippets(:public)
    @cms_site = comfy_cms_sites(:public)
  end

  test 'logged_in_user_render when used is logged in and snippet is html string' do
    @current_user = @user
    snippet = logged_in_user_render("<h1>This is test</h1>", { "html" => "true"})
    assert_equal "<h1>This is test</h1>", snippet
  end

  test 'logged_in_user_render when used is logged in and snippet identifer is passed' do
    @current_user = @user
    snippet = logged_in_user_render(@snippet.identifier)
    assert_equal @snippet.content, snippet
  end

  test 'logged_in_user_render when used is logged out and snippet identifer is passed' do
    refute logged_in_user_render(@snippet.identifier)
  end

  test 'logged_in_user_render when used is logged out and snippet is html string' do
    refute logged_in_user_render("<h1>This is test</h1>", { "html" => "true"})
  end

  test 'logged_out_user_render when used is logged in and snippet is html string' do
    snippet = logged_out_user_render("<h1>This is test</h1>", { "html" => "true"})
    assert_equal "<h1>This is test</h1>", snippet
  end

  test 'logged_out_user_render when used is logged in and snippet identifer is passed' do
    snippet = logged_out_user_render(@snippet.identifier)
    assert_equal @snippet.content, snippet
  end

  test 'logged_out_user_render when used is logged out and snippet identifer is passed' do
    @current_user = @user
    refute logged_out_user_render(@snippet.identifier)
  end

  test 'logged_out_user_render when used is logged out and snippet is html string' do
    @current_user = @user
    refute logged_out_user_render("<h1>This is test</h1>", { "html" => "true"})
  end

  def current_user
    @current_user
  end
end