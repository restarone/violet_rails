class Comfy::Admin::ApiNamespacesController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_api
  before_action :set_api_namespace, only: %i[ show edit update destroy discard_failed_api_actions rerun_failed_api_actions export duplicate_with_associations duplicate_without_associations export_without_associations_as_json export_with_associations_as_json ]

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

  def duplicate_with_associations
    response = @api_namespace.duplicate_api_namespace(duplicate_associations: true)

    respond_to do |format|
      if response[:success]
        cloned_api_namespace = response[:data]

        format.html { redirect_to api_namespace_path(id: cloned_api_namespace.id), notice: "Api namespace was successfully created." }
        format.json { render :show, status: :created, location: cloned_api_namespace }
      else
        format.html { redirect_to @api_namespace, alert: "Duplicating Api namespace failed due to: #{response[:message]}." }
        format.json { render json: response, status: :unprocessable_entity }
      end
    end
  end

  def duplicate_without_associations
    response = @api_namespace.duplicate_api_namespace

    respond_to do |format|
      if response[:success]
        cloned_api_namespace = response[:data]

        format.html { redirect_to api_namespace_path(id: cloned_api_namespace.id), notice: "Api namespace was successfully created." }
        format.json { render :show, status: :created, location: cloned_api_namespace }
      else
        format.html { redirect_to @api_namespace, alert: "Duplicating Api namespace failed due to: #{response[:message]}." }
        format.json { render json: response, status: :unprocessable_entity }
      end
    end
  end

  def export
    # Naming convention: api_namespace_<API NAMESPACE ID>_<CURRENT TIMESTAMP>.csv
    filename = "api_namespace_#{@api_namespace.id}_#{DateTime.now.to_i}.csv"
    respond_to do |format|
      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=#{filename}"
        render template: "comfy/admin/api_namespaces/export"
      end
    end
  end

  def export_without_associations_as_json
    json_str = @api_namespace.export_as_json(include_associations: false)

    send_data json_str, :type => 'application/json; header=present', :disposition => "attachment; filename=#{@api_namespace.name}_without_associations.json"
  end

  def export_with_associations_as_json
    json_str = @api_namespace.export_as_json(include_associations: true)

    send_data json_str, :type => 'application/json; header=present', :disposition => "attachment; filename=#{@api_namespace.name}_with_associations.json"
  end

  def import_as_json
    file_path = params[:file].tempfile.path
    json_str = File.read(file_path)
    response = ApiNamespace.import_as_json(json_str)

    if response[:success]
      imported_api_namespace = response[:data]

      redirect_to api_namespace_path(id: imported_api_namespace.id), notice: "Api namespace was successfully imported."
    else
      redirect_back fallback_location: api_namespaces_path, alert: "Importing Api namespace failed due to: #{response[:message]}."
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_api_namespace
      @api_namespace = ApiNamespace.friendly.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def api_namespace_params
      api_actions_attributes =  [:id, :trigger, :action_type, :properties, :include_api_resource_data, :email,:custom_message, :payload_mapping, :request_url, :redirect_url, :bearer_token, :file_snippet, :position, :custom_headers, :http_method, :_destroy]
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
      flash[:error] = @api_namespace.errors.full_messages
      redirect_to action_workflow_api_namespace_api_actions_path(api_namespace_id: @api_namespace.id) and return  if params[:source] == 'action_workflow'

      render :edit, status: :unprocessable_entity
    end
end