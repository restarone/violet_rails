class ChangeDefaultForModelDefinition < ActiveRecord::Migration[6.1]
  OLD_MODEL_DEFINITION = "raise StandardError"

  def change
    change_column_default :external_api_clients, :model_definition, from: OLD_MODEL_DEFINITION, to: ExternalApiClient::DEFAULT_MODEL_DEFINITION
  end
end
