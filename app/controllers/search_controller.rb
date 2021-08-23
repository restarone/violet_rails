class SearchController < ApplicationController
  def query
    search_q = params[:query]
    if search_q
      matching_fragments = Comfy::Cms::Fragment
        .where(record_type: "Comfy::Cms::Page")
        .where("to_tsvector(comfy_cms_fragments.content) @@ to_tsquery('english', ?)", search_q)
      site_pages = Comfy::Cms::Page
      .where(id: matching_fragments.pluck(:record_id), is_restricted: false, is_published: true)
    else
      site_pages = { status: 'search parameter not defined', code: 422 }
    end
    render json: site_pages
  end
end
