class Api::ResourceController < Api::BaseController
  def index
    render json: serialize_resource(@api_namespace.api_resources.order(updated_at: :desc))
  end

  def query
    attribute = params[:attribute]
    value = params[:value]
    results = @api_namespace.api_resources.where("properties->>'#{attribute}' = ?", "#{value}")
    render json: serialize_resource(Array.wrap(results))
  end

  def describe
    render json: @api_namespace
  end

  private

  def serialize_resource(collection)
    collection.map{|n| { created_at: n.created_at, updated_at: n.updated_at, properties: n.properties ? n.properties : nil } }.to_json
  end
end
