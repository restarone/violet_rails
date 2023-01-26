module ContentHelper
  # Usgae 1: {{ cms:helper logged_in_user_render, snippet_identifier }}
  # Usage 2: {{ cms:helper logged_in_user_render, "<span>I am logged in</span>", html: true }}  
  def logged_in_user_render(snippet, options = {})
    # pass either html string or snippet identifier
    return unless current_user.present?

    options['html'] == 'true' ? snippet.html_safe : cms_snippet_render(snippet)
  end

  # Usgae 1: {{ cms:helper logged_out_user_render, snippet_identifier }}
  # Usage 2: {{ cms:helper logged_out_user_render, "<span>I am logged in</span>", html: true }}  
  def logged_out_user_render(snippet, options = {})
    # pass either html string or snippet identifier
    return if current_user.present?

    options['html'] == 'true' ? snippet.html_safe : cms_snippet_render(snippet)
  end

  # render resource index
  # available variables on view: @api_resources, @api_namespace
  def render_api_namespace_resource_index(slug, options = {})
    set_api_html_render_flag
    scope = options["scope"] || {}
    
    api_namespace = ApiNamespace.find_by(slug: slug)
    response = api_namespace.api_resources

    response = response.where.not(user_id: nil).where(user_id: current_user&.id) if scope&.dig('current_user') == 'true'
    
    response = response.jsonb_search(:properties, scope["properties"], scope["match"]) if scope["properties"]
    response = response.jsonb_search(:properties, JSON.parse(params[:properties]).to_hash, params[:match]) if params[:properties]

    response = response.jsonb_order(options["order"]) if options["order"]

    response = response.jsonb_order(JSON.parse(params[:order]).to_hash) if params[:order].present?

    response = response.limit(options["limit"]) if options["limit"]

    snippet_identifier = options["snippet"] ? options["snippet"] : slug

    cms_dynamic_snippet_render(snippet_identifier, nil, { api_resources: response, api_namespace: api_namespace })
  end

  # render resource show
  # available variables on view: @api_resource , @api_namespace
  def render_api_namespace_resource(api_namespace_slug, options = {})
    
    set_api_html_render_flag
    @is_show_page = true
    scope = options["scope"]
    
    api_namespace = ApiNamespace.find_by(slug: api_namespace_slug)
    api_resources = api_namespace.api_resources
    
    api_resources = api_resources.where.not(user_id: nil).where(user_id: current_user&.id) if scope&.dig('current_user') == 'true'
    
    api_resources = api_resources.jsonb_search(:properties, scope["properties"], scope["match"]) if scope&.has_key?("properties")
    
    # byebug
    @api_resource_to_render = api_resources.find(params[:id])

    snippet_name = options["snippet"] ? options["snippet"] : api_namespace_slug
    
    cms_dynamic_snippet_render("#{snippet_name}-show", nil, { api_resource: @api_resource_to_render, api_namespace: api_namespace })
  rescue ActiveRecord::RecordNotFound
    render body: Rails.root.join('public', '404.html').read.html_safe, status: :not_found, layout: false
  end

  private

  def cms_dynamic_snippet_render(identifier, cms_site = @cms_site, context = {})
    cms_site = @cms_site || cms_site_detect
    snippet = cms_site&.snippets&.find_by_identifier(identifier)
    return "" unless snippet
    r = ComfortableMexicanSofa::Content::Renderer.new(snippet)
    render inline: r.render(r.nodes(r.tokenize(snippet.content_evaluated(context))))
  end

  def set_api_html_render_flag
    Current.is_api_html_renderer_request = true
  end
end
