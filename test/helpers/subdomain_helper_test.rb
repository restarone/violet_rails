require 'test_helper'

class SubDomainHelperTest < ActionView::TestCase
    include SubdomainHelper
    setup do
        @user = users(:public)
        @snippet = comfy_cms_snippets(:public)
        @cms_site = comfy_cms_sites(:public)
    
        @api_namespace_1 = api_namespaces(:one) 
        @api_resource_1= ApiResource.create(api_namespace_id: @api_namespace_1.id, properties: { title: 'test title', description: 'test description', image: 'image_link_test' })
        test_image = Rails.root.join("test/fixtures/files/fixture_image.png")
        file = Rack::Test::UploadedFile.new(test_image, "image/png")

        NonPrimitiveProperty.create!(label: "image", field_type: "file", api_namespace_id: @api_namespace_1.id)
        @prop = NonPrimitiveProperty.create!(label: "image", field_type: "file", attachment: file, api_resource_id: @api_resource_1.id)
        Current.user = @user
    end

    test 'og_metadata - update meta data from social_share_metadata in show page if social_share_metadata is set' do
        @current_user = @user
        params[:id] = @api_resource_1.id
        @is_show_page = true
        @api_namespace_1.update(social_share_metadata: {
          title: 'title',
          description: 'description',
          image: 'image'
        })
        @api_resource_1.reload
        snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: "#{@api_namespace_1.slug}-show", position: 0, content: "<%= @api_resource.properties['title'] %>")
        response = og_metadata(@is_show_page, @api_resource_1)
    
        assert_equal @prop.file_url, @api_resource_1.props['image'].file_url
        assert_equal response[:title], @api_resource_1.props['title']
        assert_equal response[:description], @api_resource_1.props['description']
    end
    
    test 'og_metadata - should display global metadata if social_share_metadata is not set' do
        @current_user = @user
        params[:id] = @api_resource_1.id
        @is_show_page = true
        snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: "#{@api_namespace_1.slug}-show", position: 0, content: "<%= @api_resource.properties['title'] %>")
        response = og_metadata(@is_show_page, @api_resource_1)
        assert_equal 'public', response[:title]
        assert_equal 'public', response[:description]
        assert_nil response[:image]
    end

    test 'og_metadata - should display global metadata if its not a show page' do
        @current_user = @user
        params[:id] = @api_resource_1.id
        @is_show_page = false
        @api_namespace_1.social_share_metadata = {
            title: 'title',
            description: 'description',
            image: 'image'
          }
        snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: "#{@api_namespace_1.slug}-show", position: 0, content: "<%= @api_resource.properties['title'] %>")
        response = og_metadata(@is_show_page,  @api_resource_1)
        assert_equal 'public', response[:title]
        assert_equal 'public', response[:description]
        assert_nil response[:image]
    end

    test 'og_metadata - should not fail because of @api_namespace instance variable' do
        @current_user = @user
        params[:id] = @api_resource_1.id
        @is_show_page = true
        @api_namespace_1.update(social_share_metadata: {
          title: 'title',
          description: 'description',
          image: 'image'
        })
        @api_namespace = api_namespaces(:two)
        @api_resource = api_resources(:two)
        @api_resource_1.reload
        snippet = Comfy::Cms::Snippet.create(site_id: @cms_site.id, label: 'clients', identifier: "#{@api_namespace_1.slug}-show", position: 0, content: "<%= @api_resource.properties['title'] %>")
        response = og_metadata(@is_show_page, @api_resource_1)
    
        assert_equal @prop.file_url, @api_resource_1.props['image'].file_url
        assert_equal response[:title], @api_resource_1.props['title']
        assert_equal response[:description], @api_resource_1.props['description']
    end
end