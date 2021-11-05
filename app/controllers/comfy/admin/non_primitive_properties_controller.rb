class Comfy::Admin::NonPrimitivePropertiesController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_web
  # before_action :set_api_namespace
  # GET /api_namespaces/:api_namespace_id/non_primitive_properties/new
  def new
    @index = params[:index]
    @non_primitive_property = NonPrimitiveProperty.new
    
    respond_to do |format|
      format.js
    end
  end

  private

  def set_api_namespace
    @api_namespace = ApiNamespace.find_by(id: params[:api_namespace_id])
  end
end