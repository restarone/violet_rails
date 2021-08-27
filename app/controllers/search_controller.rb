class SearchController < ApplicationController
  def query
    search_q = params[:query]
    if search_q
      matching_fragments = Comfy::Cms::Fragment.where("content ILIKE ?", "%#{search_q}%")
      site_pages = Comfy::Cms::Page
      .where(id: matching_fragments.pluck(:record_id), is_restricted: false, is_published: true)
    else
      site_pages = { status: 'search parameter not defined', code: 422 }
    end
    render json: site_pages
  end
end
