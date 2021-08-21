class SearchController < ApplicationController
  def query
    search_q = params[:query]
    matching_fragments = Comfy::Cms::Fragment
      .where(record_type: "Comfy::Cms::Page")
      .where("content ILIKE ?", "%#{search_q}%")
          
    site_pages = Comfy::Cms::Page
      .where.not(is_restricted: false, is_published: true)
      .where(id: matching_fragments.pluck(:record_id))

    respond_to do |format|
      format.html { redirect_to '/search' }
      format.json   { render json: site_pages }
      format.js   { render json: site_pages }
    end
  end
end
