class Comfy::Admin::ApiNamespacesController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_api
  before_action :set_api_namespace, only: %i[ show edit update destroy discard_failed_api_actions rerun_failed_api_actions]

  # GET /api_namespaces or /api_namespaces.json
  def index
    params[:q] ||= {}
    @api_namespaces_q = ApiNamespace.ransack(params[:q])
    @api_namespaces = @api_namespaces_q.result.paginate(page: params[:page], per_page: 10)
  end

  # GET /api_namespaces/1 or /api_namespaces/1.json
  def show
    params[:q] ||= {}
    @api_resources_q = @api_namespace.api_resources.ransack(params[:q])
    @api_resources = @api_resources_q.result.paginate(page: params[:page], per_page: 10)
  end

  # GET /api_namespaces/new
  def new
    @api_namespace = ApiNamespace.new
  end

  # GET /api_namespaces/1/edit
  def edit
  end

  # POST /api_namespaces or /api_namespaces.json
  def create
    @api_namespace = ApiNamespace.new(api_namespace_params)

    respond_to do |format|
      if @api_namespace.save
        format.html { redirect_to @api_namespace, notice: "Api namespace was successfully created." }
        format.json { render :show, status: :created, location: @api_namespace }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @api_namespace.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /api_namespaces/1 or /api_namespaces/1.json
  def update
    respond_to do |format|
      if @api_namespace.update(api_namespace_params)
        format.html { handle_success_redirect }
        format.json { render :show, status: :ok, location: @api_namespace }
      else
        format.html { handle_error_redirect }
        format.json { render json: @api_namespace.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /api_namespaces/1 or /api_namespaces/1.json
  def destroy
    @api_namespace.destroy
    respond_to do |format|
      format.html { redirect_to api_namespaces_url, notice: "Api namespace was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def discard_failed_api_actions
    @api_namespace.discard_failed_actions
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: "Failed api actions are discarded") }
      format.json { render json: {message: 'Failed api actions are discarded', status: :ok } }
    end
  end

  def rerun_failed_api_actions
    @api_namespace.rerun_api_actions
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: "Failed api actions reran") }
      format.json { render json: { message: 'Failed api actions reran', status: :ok } }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_api_namespace
      @api_namespace = ApiNamespace.friendly.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def api_namespace_params
      api_actions_attributes =  [:id, :trigger, :action_type, :properties, :include_api_resource_data, :email,:custom_message, :payload_mapping, :request_url, :redirect_url, :bearer_token, :file_snippet, :position, :custom_headers, :_destroy]
      params.require(:api_namespace).permit(:name,
                                            :version,
                                            :properties,
                                            :requires_authentication,
                                            :namespace_type,
                                            :has_form,
                                            non_primitive_properties_attributes: [:id, :label, :field_type, :content, :attachment, :_destroy],
                                            new_api_actions_attributes: api_actions_attributes,
                                            create_api_actions_attributes: api_actions_attributes,
                                            show_api_actions_attributes: api_actions_attributes,
                                            update_api_actions_attributes: api_actions_attributes,
                                            destroy_api_actions_attributes: api_actions_attributes,
                                            error_api_actions_attributes: api_actions_attributes,
                                           )
    end

    def handle_success_redirect
      flash[:notice] =  "Api namespace was successfully updated."
      redirect_to api_namespace_api_actions_path(api_namespace_id: @api_namespace.id) and return  if params[:source] == 'action_workflow'

      redirect_to @api_namespace
    end

    def handle_error_redirect
      redirect_to action_workflow_api_namespace_api_actions_path(api_namespace_id: @api_namespace.id) and return  if params[:source] == 'action_workflow'

      render :edit, status: :unprocessable_entity
    end
end