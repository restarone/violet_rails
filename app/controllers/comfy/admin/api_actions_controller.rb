class Comfy::Admin::ApiActionsController < Comfy::Admin::Cms::BaseController
    before_action :ensure_authority_to_manage_web
    # before_action :set_api_namespace
    # GET /api_namespaces/:api_namespace_id/non_primitive_properties/new
    def new
      @index = params[:index]
      @api_action = ApiAction.new
      
      respond_to do |format|
        format.js
      end
    end
  
    private
  
    def set_api_namespace
      @api_namespace = ApiNamespace.find_by(id: params[:api_namespace_id])
    end
  end