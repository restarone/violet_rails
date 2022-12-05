class Comfy::Admin::ExternalApiClientsController < Comfy::Admin::Cms::BaseController
    before_action :set_external_api_client, only: %i[ show edit update destroy start stop clear_errors clear_state]
    before_action :set_api_namespace
    before_action :ensure_authority_for_read_external_api_connections_only_in_api, only: %i[ show index ]
    before_action :ensure_authority_for_full_access_for_external_api_connections_only_in_api, only: %i[ new edit create update destroy start stop clear_errors clear_state ]
  
    # GET /external_api_clients or /external_api_clients.json
    def index
      @external_api_clients = @api_namespace.external_api_clients
    end
  
    # GET /external_api_clients/1 or /external_api_clients/1.json
    def show
    end
  
    # GET /external_api_clients/new
    def new
      @external_api_client = ExternalApiClient.new(api_namespace_id: @api_namespace.id)
    end
  
    # GET /external_api_clients/1/edit
    def edit
    end
  
    # POST /external_api_clients or /external_api_clients.json
    def create
      @external_api_client = ExternalApiClient.new(external_api_client_params)
      respond_to do |format|
        if @external_api_client.save
          format.html { redirect_to api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id), notice: "Api client was successfully created." }
          format.json { render :show, status: :created, location: @api_client }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @external_api_client.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PATCH/PUT /external_api_clients/1 or /external_api_clients/1.json
    def update
      respond_to do |format|
        if @external_api_client.update(external_api_client_params)
          format.html { redirect_to api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @external_api_client.id), notice: "Api client was successfully updated." }
          format.json { render :show, status: :ok, location: @external_api_client }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @api_client.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /external_api_clients/1 or /external_api_clients/1.json
    def destroy
      @external_api_client.destroy
      respond_to do |format|
        format.html { redirect_to api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id), notice: "Api client was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    # GET /external_api_clients/1/start
    def start
      @external_api_client.run
      redirect_back(fallback_location: api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id))
    end

    # GET /external_api_clients/1/stop
    def stop
      @external_api_client.stop
      redirect_back(fallback_location: api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id))
    end

    # GET /external_api_clients/1/clear_errors
    def clear_errors
      @external_api_client.clear_error_data
      redirect_back(fallback_location: api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id))
    end

    # GET /external_api_clients/1/clear_state
    def clear_state
      @external_api_client.clear_state_data
      redirect_back(fallback_location: api_namespace_external_api_clients_path(api_namespace_id: @api_namespace.id))
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_api_namespace
        @api_namespace = ApiNamespace.friendly.find(params[:api_namespace_id]) rescue nil
      end
  
  
      def set_external_api_client
        @external_api_client = ExternalApiClient.find(params[:id])
      end
  
      # Only allow a list of trusted parameters through.
      def external_api_client_params
        params
          .require(:external_api_client)
          .permit(
            :api_namespace_id, 
            :label, 
            :metadata,
            :enabled,
            :drive_strategy,
            :max_requests_per_minute,
            :max_workers,
            :model_definition,
            :drive_every
          ).merge({
            api_namespace_id: @api_namespace.id,
          })
      end
  end
  