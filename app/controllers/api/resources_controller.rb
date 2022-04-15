class Api::ResourcesController < ActionController::Base
  def index
    @api_resources = ApiNamespace.where(requires_authentication: false)
    if @api_resources.size > 0
      render json: ApiNamespaceSerializer.new(@api_resources).serializable_hash
    else
      render json: {code: 404, status: 'not found'}
    end
  end
end
