module ApplicationHelper
  def display_subdomain_name(schema_path)
    subdomain = schema_path != Subdomain::ROOT_DOMAIN_NAME ? schema_path : 'www'
    "#{subdomain}.#{ENV['APP_HOST']}"
  end

  def page_entries_info(collection)
    model_name = collection.respond_to?(:human_name) ? collection.model_name.human : (collection.first&.model_name&.human || '')

    sanitize "Displaying #{model_name} " +
      tag.b("#{collection.offset + 1} - #{[collection.per_page * collection.current_page, collection.total_entries].min}") +
      ' of ' + tag.b(collection.total_entries) +
      ' in total'
  end

  def execute_actions(resource, class_name)
    api_actions = resource.send(class_name)
    api_actions.each do |api_action|
      api_action.execute_action unless api_action.serve_file? || api_action.redirect? || api_action.custom_action?
    end
  end

  def file_id_from_snippet(file_snippet)
    ComfortableMexicanSofa::Content::Renderer.new(:page).tokenize(file_snippet).last[:tag_params]
  end

  # Action name supports only alphanumeric characters, underscores and slash(/)
  # reference: https://developers.google.com/recaptcha/docs/faq#what-action-names-are-valid
  def sanitize_recaptcha_action_name(action_name)
    action_name.strip.gsub(/[- ]/, '_').scan(/[\/\_a-zA-Z0-9]/).join
  end

  def mobile?
    request&.user_agent&.include?('VioletRailsiOS')
  end

  def render_smart_navbar
    # conditionally renders a navbar for web / none for native in CMS
    unless mobile?
      return cms_snippet_render('navbar').html_safe
    end
  end

  def render_smart_footer
    # conditionally renders a navbar for footer / none for native in CMS
    unless mobile?
      return cms_snippet_render('footer').html_safe
    end
  end

  def show_cookies_consent_banner?
    Subdomain.current.tracking_enabled? && cookies[:cookies_accepted].nil?
  end

  def render_cookies_consent_ui
    if show_cookies_consent_banner?
      if @cms_page.present?
        context = @cms_page
      else
        cms_site = @site || cms_site_detect
        [:pages, :blog_posts, :snippets, :layouts].any? do |association|
          cms_site.send(association).present? && (context = cms_site.send(association).first)
        end
      end

      r = ComfortableMexicanSofa::Content::Renderer.new(context)
      html_text = r.render(r.nodes(r.tokenize(Subdomain.current.cookies_consent_ui)))

      render partial: 'shared/cookies_consent_ui', locals: {html_text: html_text}
    end
  end
end
