module SearchHelper

  def render_search_field
    # usage in cms  {{ cms:helper render_search_field }}
    # usage in rails = render_search_field
    render partial: 'comfy/helpers/search/render'
  end
end
