# frozen_string_literal: true

class HomeController < StoreController
  helper 'spree/products'
  respond_to :html

  def index
    @searcher = build_searcher(params.merge(include_images: true))
    @products = @searcher.retrieve_products
  end
end
