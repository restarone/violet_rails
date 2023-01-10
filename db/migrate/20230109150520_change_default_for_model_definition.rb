class ChangeDefaultForModelDefinition < ActiveRecord::Migration[6.1]
  OLD_MODEL_DEFINITION = "raise StandardError"

  def up
    change_column :external_api_clients, :model_definition, :text, default: ExternalApiClient::DEFAULT_MODEL_DEFINITION

    ExternalApiClient.where(model_definition: OLD_MODEL_DEFINITION).update_all(model_definition: ExternalApiClient::DEFAULT_MODEL_DEFINITION)
  end

  def down
    change_column :external_api_clients, :model_definition, :text, default: OLD_MODEL_DEFINITION

    ExternalApiClient.where(model_definition: ExternalApiClient::DEFAULT_MODEL_DEFINITION).update_all(model_definition: OLD_MODEL_DEFINITION)
  end
end
