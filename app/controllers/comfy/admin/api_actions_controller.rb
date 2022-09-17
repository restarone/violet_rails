class Comfy::Admin::ApiActionsController < Comfy::Admin::Cms::BaseController
  before_action :set_api_action
  before_action :ensure_authority_for_read_api_actions_only_in_api, only: %i[ show ]
  before_action :ensure_authority_for_full_access_for_api_actions_only_in_api, only: %i[ new edit create update destroy ]
  before_action :set_current_user_and_visit

  def new
    @index = params[:index]
    @type = params[:type]
    @api_action = ApiAction.new(type: params[:type].classify, position: @index)
    
    respond_to do |format|
      format.js
    end
  end

  def index
    params[:q] ||= {}
    @api_actions_q = @api_namespace.executed_api_actions.order(created_at: :desc).ransack(params[:q])
    @api_actions = @api_actions_q.result.paginate(page: params[:page], per_page: 10)
  end

  def show
  end

  def action_workflow
    
  end

  private

  def set_api_action
    @api_namespace = ApiNamespace.find_by(id: params[:api_namespace_id])
    @api_action = @api_namespace.executed_api_actions.find_by(id: params[:id])
  end

  def set_current_user_and_visit
    Current.user = current_user
    Current.visit = current_visit
  end
end