class Api::ResourceController < Api::BaseController
  before_action :load_api_resource, only: [:show]


  def index
    render json: serialize_resources(@api_namespace.api_resources.order(updated_at: :desc))
  end

  def query
    attribute = params[:attribute]
    value = params[:value]
    results = @api_namespace.api_resources.where("properties ->> :key ILIKE :value",
      key: attribute, value: "%#{value}%"
    )
    render json: serialize_resources(Array.wrap(results))
  end

  def describe
    render json: @api_namespace
  end

  def show
    if @api_resource
      render json: serialize_resource(@api_resource)
    else
      render json: {code: 404, status: 'not found'}
    end
  end

  private

  def load_api_resource
    @api_resource = @api_namespace.api_resources.find_by(id: params[:api_resource_id])
  end

  def serialize_resources(collection)
    collection.map{|n| { id: n.id, created_at: n.created_at, updated_at: n.updated_at, properties: n.properties ? n.properties : nil } }
  end

  def serialize_resource(resource)
    { id: resource.id, created_at: resource.created_at, updated_at: resource.updated_at, properties: resource.properties ? resource.properties : nil }
  end
end
