class SearchController < ApplicationController
  def query
    search_q = params[:query]
    pages = Comfy::Cms::Page.ransack(search_q)
    render json: pages.result
  end
end
