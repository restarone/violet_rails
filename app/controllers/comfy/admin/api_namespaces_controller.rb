class Comfy::Admin::ApiNamespacesController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_web
  before_action :set_api_namespace, only: %i[ show edit update destroy ]

  # GET /api_namespaces or /api_namespaces.json
  def index
    @api_namespaces = ApiNamespace.all
  end

  # GET /api_namespaces/1 or /api_namespaces/1.json
  def show
    @api_resources = @api_namespace.api_resources
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
        format.html { redirect_to @api_namespace, notice: "Api namespace was successfully updated." }
        format.json { render :show, status: :ok, location: @api_namespace }
      else
        format.html { render :edit, status: :unprocessable_entity }
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_api_namespace
      @api_namespace = ApiNamespace.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def api_namespace_params
      params.require(:api_namespace).permit(:name, :version, :properties, :requires_authentication, :namespace_type)
    end
end
