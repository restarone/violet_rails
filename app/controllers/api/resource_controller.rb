class Api::ResourceController < Api::BaseController
  before_action :load_api_resource, only: [:show, :update, :destroy]
  before_action :prevent_write_access_if_public, only: [:create, :update, :destroy]

  before_action :validate_payload, only: [:create, :update]

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

  def create
    api_resource = @api_namespace.api_resources.new(resource_params)
    if api_resource.save
        render json: { code: 200, status: 'OK', object: serialize_resource(api_resource) }
      else
        render json: { code: 400, status: api_resource.errors.full_messages.to_sentence }
    end
  end

  def update
    before_change = @api_resource.dup
    if @api_resource.update(resource_params)
      render json: { code: 200, status: 'OK', object: serialize_resource(@api_resource.reload), before: serialize_resource(before_change) }
    else
      render json: { code: 422, status: 'unprocessable entity' }
    end
  end

  def destroy
    if @api_resource.destroy
      render json: { code: 200, status: 'OK', object: serialize_resource(@api_resource) }
    else
      render json: { code: 422, status: 'unprocessable entity' }
    end
  end

  private

  def validate_payload
    unless params[:data]
      render json: { status: 'Please make sure that your parameters are provided under a data: {} top-level key', code: 422 }
    end
  end

  def prevent_write_access_if_public
    unless @api_namespace.requires_authentication
      render json: { status: 'write access is disabled by default for public access namespaces', code: 403 }
    end
  end

  def load_api_resource
    @api_resource = @api_namespace.api_resources.find_by(id: params[:api_resource_id])
    unless @api_resource 
      render json: { status: 'not found', code: 404 }
    end
  end

  def resource_params
    params.require(:data).permit(properties: {}, non_primitive_properties_attributes: [:id, :label, :field_type, :content, :attachment, :_destroy])
  end

  def serialize_resources(collection)
    collection.map{|n| { id: n.id, created_at: n.created_at, updated_at: n.updated_at, properties: n.properties ? n.properties : nil } }
  end

  def serialize_resource(resource)
    { id: resource.id, created_at: resource.created_at, updated_at: resource.updated_at, properties: resource.properties ? resource.properties : nil }
  end
end
