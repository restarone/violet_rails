class ChangeDefaultForModelDefinition < ActiveRecord::Migration[6.1]
  OLD_MODEL_DEFINITION = "raise StandardError"
  
  NEW_MODEL_DEFINITION = 
"class ApiConnectionExample
  def initialize(parameters)
    @external_api_client = parameters[:external_api_client]
    @api_namespace = @external_api_client.api_namespace

    # rails request object accessable for webhook, https://api.rubyonrails.org/classes/ActionDispatch/Request.html
    # commonly used request methods: request_parameters, headers
    # @request = parameters[:request]
  end

  def start
    # render response incase of webhook
    # render json: { success: true }
  end
end

ApiConnectionExample"

  def up
    change_column :external_api_clients, :model_definition, :text, default: NEW_MODEL_DEFINITION

    ExternalApiClient.where(model_definition: OLD_MODEL_DEFINITION).update_all(model_definition: NEW_MODEL_DEFINITION)
  end

  def down
    change_column :external_api_clients, :model_definition, :text, default: OLD_MODEL_DEFINITION

    ExternalApiClient.where(model_definition: NEW_MODEL_DEFINITION).update_all(model_definition: OLD_MODEL_DEFINITION)
  end
end
