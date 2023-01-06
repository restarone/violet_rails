class Api::ExternalApiClientsController < Api::BaseController
    before_action :find_external_api_client
    skip_before_action :authenticate_request

    def webhook
      # should only exist if drive strategy is webhook
      raise ActionController::RoutingError.new('Not Found') unless @external_api_client.drive_strategy == ExternalApiClient::DRIVE_STRATEGIES[:webhook]

      return render json: { message: 'Webhook not enabled', success: false }, status: 400 unless @external_api_client.enabled

      if @external_api_client.webhook_verification_method.present?
        verified, message = Webhook::Verification.new(request, @external_api_client.webhook_verification_method).call

        return render json: { message: message, success: false }, status: 401 unless verified
      end

      model_definition = @external_api_client.evaluated_model_definition

      # add render method on model_definition
      # render should only be available on controller context
      model_definition.define_method(:render) do |args|
        return { render: true, args: args } 
      end

      response = model_definition.new(external_api_client: @external_api_client, request: { body: JSON.parse(request.body.read) }.deep_stringify_keys).start

      render response[:args] if response.is_a?(Hash) && response[:render]
    end

    private

    def find_external_api_client
      @external_api_client = ExternalApiClient.find_by(slug: params[:external_api_client])
    end
end