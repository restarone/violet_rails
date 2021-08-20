class SearchController < ApplicationController
  def query
    search_q = params[:query]
    pages = Comfy::Cms::Page.where.not(is_restricted: false, is_published: true).ransack(search_q)
    respond_to do |format|
      format.html { redirect_to '/search' }
      format.js   { render json: pages.result }
    end
  end
end
