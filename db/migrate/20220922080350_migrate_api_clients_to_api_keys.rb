class MigrateApiClientsToApiKeys < ActiveRecord::Migration[6.1]
  def change
    ApiClient.all.each do |api_client|
      api_key = ApiKey.create!(slug: api_client.slug, label: api_client.label, bearer_token: api_client.bearer_token, authentication_strategy: api_client.authentication_strategy)
      ApiNamespaceKey.create(api_namespace_id: api_client.api_namespace_id, api_key_id: api_key.id)
    end
  end
end
