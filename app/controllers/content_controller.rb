class ContentController < ApplicationController
  def index
    if current_customer
      redirect_to root_path(subdomain: current_customer.subdomain)
    end
  end
end
