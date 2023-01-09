class Api::ExternalApiClientsController < Api::BaseController
    before_action :find_external_api_client
    after_action :unload_api_connection_class, only: :webhook
    skip_before_action :authenticate_request

    def webhook
      # should only exist if drive strategy is webhook
      raise ActionController::RoutingError.new('Not Found') unless @external_api_client.drive_strategy == ExternalApiClient::DRIVE_STRATEGIES[:webhook]

      return render json: { message: 'Webhook not enabled', success: false }, status: 400 unless @external_api_client.enabled

      if @external_api_client.webhook_verification_method.present?
        verified, message = Webhook::Verification.new(request, @external_api_client.webhook_verification_method).call

        return render json: { message: message, success: false }, status: 401 unless verified
      end

      @model_definition = @external_api_client.evaluated_model_definition

      # add render method on model_definition
      # render should only be available on controller context
      @model_definition.define_method(:render) do |args|
        return { render: true, args: args } 
      end

      response = @model_definition.new(external_api_client: @external_api_client, request: request).start

      render response[:args] if response.is_a?(Hash) && response[:render]
    end

    private

    def unload_api_connection_class
      ExternalApiClient.send(:remove_const, @model_definition.name.split('::').last.to_sym) if @model_definition
    end

    def find_external_api_client
      @external_api_client = ExternalApiClient.find_by(slug: params[:external_api_client])
    end
end