class Api::ExternalApiClientsController < Api::BaseController
    before_action :find_external_api_client

    def webhook
      raise ActionController::RoutingError.new('Not Found') unless @external_api_client.drive_strategy == ExternalApiClient::DRIVE_STRATEGIES[:web_hook]

      @external_api_client.run
      render json: { success: true }
    end

    def find_external_api_client
      @external_api_client = ExternalApiClient.find_by(slug: params[:external_api_client])
    end
end