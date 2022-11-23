class Api::ExternalApiClientsController < Api::BaseController
    before_action :find_external_api_client
    skip_before_action :authenticate_request

    def webhook
      # should only exist if drive strategy is webhook
      raise ActionController::RoutingError.new('Not Found') unless @external_api_client.drive_strategy == ExternalApiClient::DRIVE_STRATEGIES[:webhook]

      return render json: { message: 'Webhook not enabled', success: false }, status: 400 unless @external_api_client.enabled

      if @external_api_client.webhook_verification_method.present?
        verified, message = Webhook::Verification.new(request, @external_api_client.webhook_verification_method).call

        return render json: { message: message, success: false }, status: 400 unless verified
      end

      @external_api_client.run({ request: { body: JSON.parse(request.body.read) } })
      
      render json: { success: true }
    end

    private

    def find_external_api_client
      @external_api_client = ExternalApiClient.find_by(slug: params[:external_api_client])
    end
end