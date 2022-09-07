require 'test_helper'

class ContentHelperTest < ActionView::TestCase
  include Comfy::CmsHelper

  setup do
    @user = users(:public)
    @snippet = comfy_cms_snippets(:public)
    @cms_site = comfy_cms_sites(:public)

    @api_namespace = api_namespaces(:one) 
    @api_resource = ApiResource.create(api_namespace_id: @api_namespace.id, properties: { name: 'test user 0' })
    
    Current.user = @user
    @api_resource_1 = ApiResource.create(api_namespace_id: @api_namespace.id, properties: { name: 'test user 1' })
    @api_resource_2 = ApiResource.create(api_namespace_id: @api_namespace.id, properties: { name: 'test user 2' })
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

  test 'render_api_namespace_resource_index - no scope' do
    Current.user = @user
    @current_user = @user

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")

    # should show all api_namespace api_resources 
    response = render_api_namespace_resource_index(@api_namespace.slug)
    excepted_response = @api_namespace.api_resources.map{ |ap| ap.properties['name'] }.join
    assert_equal excepted_response, response
  end

  test 'render_api_namespace_resource_index - current user scope' do
    @current_user = @user
    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    # current_user scope: should show api_resources created by current user
    response = render_api_namespace_resource_index(@api_namespace.slug, { 'scope' => { 'current_user' => 'true' } })
    excepted_response = "#{@api_resource_1.properties['name']}#{@api_resource_2.properties['name']}"
    assert_equal excepted_response, response
  end

  test 'render_api_namespace_resource_index - current user scope - unhappy path' do
    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    # current_user scope: should show api_resources created by current user
    response = render_api_namespace_resource_index(@api_namespace.slug, { 'scope' => { 'current_user' => 'true' } })
    assert_equal "", response
  end

  test 'render_api_namespace_resource_index - properties scope' do
    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug, { 'scope' => { 'properties' => { 'name': 'test user 1' } } })
    excepted_response = "#{@api_resource_1.properties['name']}"
    assert_equal excepted_response, response
  end

  test 'render_api_namespace_resource_index - properties scope - unhappy path' do
    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug, { 'scope' => { 'properties' => { 'name': 'test user 3' } } })
    assert_equal "", response
  end

  test 'render_api_namespace_resource_index - filter by params' do
    params[:properties] = {name: 'test user 1'}.to_json

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug)
    excepted_response = "#{@api_resource_1.properties['name']}"
    assert_equal excepted_response, response
  end

  test 'render_api_namespace_resource_index - filter by params - partial match' do
    params[:properties] = {name: { value: 'test user', option: 'PARTIAL' }}.to_json

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug)
    excepted_response = "#{@api_resource.properties['name']}#{@api_resource_1.properties['name']}#{@api_resource_2.properties['name']}"
    assert_equal excepted_response, response
  end

  test 'render_api_namespace_resource_index - unhappy response' do
    params[:properties] = {name: 'test user 4'}.to_json

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug)

    assert_equal "", response
  end

  test 'render_api_namespace_resource_index - scope & filter by params' do
    @current_user = @user
    params[:properties] = {name: { value: 'test user', option: 'PARTIAL' }}.to_json

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug, { 'scope' => { 'current_user' => 'true' } })
    excepted_response = "#{@api_resource_1.properties['name']}#{@api_resource_2.properties['name']}"
    assert_equal excepted_response, response
  end

  test 'render_api_namespace_resource_index - scope & filter by params - unhappy response' do
    @current_user = @user
    params[:properties] = {name: 'test user 0'}.to_json

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug, { 'scope' => { 'current_user' => 'true' } })

    # should not be able to filter api resources blocked by scope
    assert_equal "", response
  end

  test 'render_api_namespace_resource - no scope' do
    params[:id] = @api_resource.id

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: "#{@api_namespace.slug}-show", position: 0, content: "<%= @api_resource.properties['name'] %>")

    response = render_api_namespace_resource(@api_namespace.slug)

    assert_equal @api_resource.properties['name'], response
  end

  test 'render_api_namespace_resource - no scope - 404' do
    params[:id] = 'not a id'

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: "#{@api_namespace.slug}-show", position: 0, content: "<%= @api_resource.properties['name'] %>")

    # should raise 404 if record not found 
    assert_raises ActiveRecord::RecordNotFound do
      response = render_api_namespace_resource(@api_namespace.slug)
    end
  end

  test 'render_api_namespace_resource - with scope' do
    @current_user = @user
    params[:id] = @api_resource_1.id

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: "#{@api_namespace.slug}-show", position: 0, content: "<%= @api_resource.properties['name'] %>")

    response = render_api_namespace_resource(@api_namespace.slug, { 'scope' => { 'current_user' => 'true' } })

    assert_equal @api_resource_1.properties['name'], response
  end

  test 'render_api_namespace_resource - with scope - 404' do
    @current_user = @user
    params[:id] = @api_resource.id

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: "#{@api_namespace.slug}-show", position: 0, content: "<%= @api_resource.properties['name'] %>")

    # should not be able to find records blocked by scope
    assert_raises ActiveRecord::RecordNotFound do
      response = render_api_namespace_resource(@api_namespace.slug, { 'scope' => { 'current_user' => 'true' } })
    end
  end

  test 'render_api_namespace_resource_index - sort jsonb - ASC' do
    params[:order] = {properties: {name: 'ASC'}}.to_json

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug)
    excepted_response = "#{@api_resource.properties['name']}#{@api_resource_1.properties['name']}#{@api_resource_2.properties['name']}"
    assert_equal excepted_response, response
  end

  test 'render_api_namespace_resource_index - sort jsonb - DESC' do
    params[:order] = {properties: {name: 'DESC'}}.to_json

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug)
    excepted_response = "#{@api_resource_2.properties['name']}#{@api_resource_1.properties['name']}#{@api_resource.properties['name']}"
    assert_equal excepted_response, response
  end

  test 'render_api_namespace_resource_index - scope & filter by params and sort ASC' do
    @current_user = @user
    params[:properties] = {name: { value: 'test user', option: 'PARTIAL' }}.to_json
    params[:order] = {properties: {name: 'ASC'}}.to_json

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug, { 'scope' => { 'current_user' => 'true' } })
    excepted_response = "#{@api_resource_1.properties['name']}#{@api_resource_2.properties['name']}"
    assert_equal excepted_response, response
  end

  test 'render_api_namespace_resource_index - scope & filter by params and sort DESC' do
    @current_user = @user
    params[:properties] = {name: { value: 'test user', option: 'PARTIAL' }}.to_json
    params[:order] = {properties: {name: 'DESC'}}.to_json

    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug, { 'scope' => { 'current_user' => 'true' } })
    excepted_response = "#{@api_resource_2.properties['name']}#{@api_resource_1.properties['name']}"
    assert_equal excepted_response, response
  end

  test 'render_api_namespace_resource_index - order from params should overrride predefined order' do
    snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: @api_namespace.slug, position: 0, content: "<% @api_resources.each do |res| %><%= res.properties['name'] %><% end %>")
    
    response = render_api_namespace_resource_index(@api_namespace.slug, {'order' => { 'properties' => { 'name' => 'DESC' } } } )
    excepted_response = "#{@api_resource_2.properties['name']}#{@api_resource_1.properties['name']}#{@api_resource.properties['name']}"
    assert_equal excepted_response, response

    params[:order] = {properties: {name: 'ASC'}}.to_json

    response = render_api_namespace_resource_index(@api_namespace.slug, {'order' => { 'properties' => { 'name' => 'DESC' } } } )
    excepted_response = "#{@api_resource.properties['name']}#{@api_resource_1.properties['name']}#{@api_resource_2.properties['name']}"
    assert_equal excepted_response, response
  end

  def current_user
    @current_user
  end
end