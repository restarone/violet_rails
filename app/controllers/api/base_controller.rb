class Api::BaseController < ActionController::API
  before_action :parse_request,
                :authenticate_request
  def authenticate_request
    if @api_namespace.requires_authentication
      unless validate_bearer_token
        render json: { status: 'unauthorized', code: 401 }, status: 401
      end
    end
  end

  private

  def validate_bearer_token
    bearer_token = request.headers['Authorization']
    if bearer_token
      token = bearer_token.split(' ')[1]
      api_key = @api_namespace.api_keys.any? { |api_key| api_key.token == token }
      if api_key
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def parse_request
    @resource_slug = params[:api_namespace]
    @resource_version = params[:version]
    if params[:id]
      @resource_identifier = params[:id]
    end
    @api_namespace = ApiNamespace.find_by(slug: @resource_slug, version: @resource_version)
    unless @api_namespace
      render json: { status: 'not found', code: 404 }
    end
  end
end
