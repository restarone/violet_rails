class Api::BaseController < ActionController::API
  before_action :parse_request,
                :authenticate_request
  def authenticate_request
    if @api_namespace.requires_authentication
      render json: { status: 'unauthorized', code: 401 }
    end
  end

  private

  def parse_request
    @resource_name = params[:api_namespace]
    @resource_version = params[:version]
    if params[:id]
      @resource_identifier = params[:id]
    end
    @api_namespace = ApiNamespace.find_by(name: @resource_name, version: @resource_version)
    unless @api_namespace
      render json: { status: 'not found', code: 404 }
    end
  end
end
