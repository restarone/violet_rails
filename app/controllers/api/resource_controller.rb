class Api::ResourceController < Api::BaseController
  def index
    render json: helpers.serialize_resource(@api_namespace.api_resources.order(updated_at: :desc))
  end

  def describe
    render json: @api_namespace
  end
end
