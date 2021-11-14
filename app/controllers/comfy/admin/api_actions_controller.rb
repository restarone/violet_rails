class Comfy::Admin::ApiActionsController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_api
  def new
    @index = params[:index]
    @type = params[:type]
    @api_action = ApiAction.new(type: params[:type].classify, position: @index)
    
    respond_to do |format|
      format.js
    end
  end

  private

  def set_api_namespace
    @api_namespace = ApiNamespace.find_by(id: params[:api_namespace_id])
  end
end