class Comfy::Admin::ApiClientsController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_api
  before_action :set_api_client, only: %i[ show edit update destroy ]
  before_action :set_api_namespace

  # GET /api_clients or /api_clients.json
  def index
    @api_clients = @api_namespace.api_clients
  end

  # GET /api_clients/1 or /api_clients/1.json
  def show
  end

  # GET /api_clients/new
  def new
    @api_client = ApiClient.new(api_namespace_id: @api_namespace.id)
  end

  # GET /api_clients/1/edit
  def edit
  end

  # POST /api_clients or /api_clients.json
  def create
    @api_client = ApiClient.new(api_client_params)
    respond_to do |format|
      if @api_client.save
        format.html { redirect_to api_namespace_api_client_path(api_namespace_id: @api_namespace.id, id: @api_client.id), notice: "Api client was successfully created." }
        format.json { render :show, status: :created, location: @api_client }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @api_client.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /api_clients/1 or /api_clients/1.json
  def update
    respond_to do |format|
      if @api_client.update(api_client_params)
        format.html { redirect_to api_namespace_api_client_path(api_namespace_id: @api_namespace.id, id: @api_client.id), notice: "Api client was successfully updated." }
        format.json { render :show, status: :ok, location: @api_client }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @api_client.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /api_clients/1 or /api_clients/1.json
  def destroy
    @api_client.destroy
    respond_to do |format|
      format.html { redirect_to api_namespace_api_clients_path(api_namespace_id: @api_namespace.id), notice: "Api client was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_api_namespace
      @api_namespace = ApiNamespace.find_by(id: params[:api_namespace_id])
    end


    def set_api_client
      @api_client = ApiClient.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def api_client_params
      params.require(:api_client).permit(:api_namespace_id, :label, :authentication_strategy).merge({api_namespace_id: @api_namespace.id})
    end
end
