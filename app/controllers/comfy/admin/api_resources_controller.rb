class Comfy::Admin::ApiResourcesController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_web
  before_action :set_api_resource, only: %i[ show edit update destroy ]

  # GET /api_resources or /api_resources.json
  def index
    @api_resources = ApiResource.all
  end

  # GET /api_resources/1 or /api_resources/1.json
  def show
  end

  # GET /api_resources/new
  def new
    @api_resource = ApiResource.new
  end

  # GET /api_resources/1/edit
  def edit
  end

  # POST /api_resources or /api_resources.json
  def create
    @api_resource = ApiResource.new(api_resource_params)

    respond_to do |format|
      if @api_resource.save
        format.html { redirect_to @api_resource, notice: "Api resource was successfully created." }
        format.json { render :show, status: :created, location: @api_resource }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @api_resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /api_resources/1 or /api_resources/1.json
  def update
    respond_to do |format|
      if @api_resource.update(api_resource_params)
        format.html { redirect_to @api_resource, notice: "Api resource was successfully updated." }
        format.json { render :show, status: :ok, location: @api_resource }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @api_resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /api_resources/1 or /api_resources/1.json
  def destroy
    @api_resource.destroy
    respond_to do |format|
      format.html { redirect_to api_resources_url, notice: "Api resource was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_api_resource
      @api_resource = ApiResource.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def api_resource_params
      params.require(:api_resource).permit(:api_namespace_id, :properties)
    end
end
