class Api::ResourceController < Api::BaseController
  def index
  end

  def describe
    render json: @api_namespace
  end

  def show
  end
end
