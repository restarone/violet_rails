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
end