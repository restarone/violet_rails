class Api::ResourceController < Api::BaseController
  def index
    render json: @api_namespace.api_resources
  end

  def describe
    render json: @api_namespace
  end

  def show
  end
end
