class Comfy::Admin::ApiResourcesController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_api
  before_action :set_api_resource

  include ApiActionable
  # GET /api_resources or /api_resources.json
  def index
    @api_resources = ApiResource.all
  end

  # GET /api_resources/1 or /api_resources/1.json
  def show
    handle_redirection if @redirect_action.present?
  end

  # GET /api_resources/new
  def new
    @api_resource = ApiResource.new(api_namespace_id: @api_namespace.id)
  end

  # GET /api_resources/1/edit
  def edit
  end

  # POST /api_resources or /api_resources.json
  def create
    @api_resource = ApiResource.new(api_resource_params)

    respond_to do |format|
      if @api_resource.save
        format.html { redirect_to api_namespace_resource_path(api_namespace_id: @api_resource.api_namespace_id,id: @api_resource.id), notice: "Api resource was successfully created." }
        format.json { render :show, status: :created, location: @api_resource }
      else
        execute_error_actions
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @api_resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /api_resources/1 or /api_resources/1.json
  def update
    respond_to do |format|
      if @api_resource.update(api_resource_params)
        format.html {  handle_redirection }
        format.json { render :show, status: :ok, location: @api_resource }
      else
        execute_error_actions
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @api_resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /api_resources/1 or /api_resources/1.json
  def destroy
    @api_resource.destroy
    respond_to do |format|
      format.html { redirect_to api_namespace_path(id: @api_namespace.id), notice: "Api resource was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_api_resource
      @api_namespace = ApiNamespace.find_by(id: params[:api_namespace_id])
      @api_resource = @api_namespace.api_resources.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def api_resource_params
      params.require(:api_resource).permit(:properties, non_primitive_properties_attributes: [:id, :label, :field_type, :content, :attachment, :_destroy]).merge({ api_namespace_id: params[:api_namespace_id] })
    end
end
