module SearchHelper

  def render_search_field(ajax = true)
    # usage in cms  {{ cms:helper render_search_field, false }}
    # usage in rails = render_search_field false
    render partial: 'comfy/helpers/search/render', locals: { ajax:  ajax }
  end
end
