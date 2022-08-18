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

  def render_api_namespace_resource_index(slug)
    byebug
    cms_snippet_render(slug)
  end
end
