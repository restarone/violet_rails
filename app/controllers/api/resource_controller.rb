class Api::ResourceController < Api::BaseController
  before_action :load_api_resource, only: [:show, :update, :destroy]
  before_action :prevent_write_access_if_public, only: [:create, :update, :destroy]

  before_action :validate_payload, only: [:create, :update]

  def index
    render json: ApiResourceSerializer.new(@api_namespace.api_resources.order(updated_at: :desc)).serializable_hash
  end

  def query
    attribute = params[:attribute]
    value = params[:value]
    results = @api_namespace.api_resources.where("properties ->> :key ILIKE :value",
      key: attribute, value: "%#{value}%"
    )
    render json: ApiResourceSerializer.new(Array.wrap(results)).serializable_hash
  end

  def describe
    render json: @api_namespace, include: :non_primitive_properties
  end

  def show
    if @api_resource
      render json: ApiResourceSerializer.new(@api_resource).serializable_hash
    else
      render json: {code: 404, status: 'not found'}
    end
  end

  def create
    api_resource = @api_namespace.api_resources.new(
      properties: resource_params[:data]
    )
    if api_resource.save
        render json: { code: 200, status: 'OK', object: ApiResourceSerializer.new(api_resource).serializable_hash }
      else
        render json: { code: 400, status: api_resource.errors.full_messages.to_sentence }
    end
  end

  def update
    before_change = @api_resource.dup
    if @api_resource.update(
      properties: resource_params[:data],
    )
      render json: { code: 200, status: 'OK', object: ApiResourceSerializer.new(@api_resource.reload).serializable_hash, before: ApiResourceSerializer.new(before_change).serializable_hash }
    else
      render json: { code: 422, status: 'unprocessable entity' }
    end
  end

  def destroy
    if @api_resource.destroy
      render json: { code: 200, status: 'OK', object: ApiResourceSerializer.new(@api_resource).serializable_hash }
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
    params.permit(data: {})
  end
end
