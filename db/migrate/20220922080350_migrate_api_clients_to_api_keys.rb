class MigrateApiClientsToApiKeys < ActiveRecord::Migration[6.1]
  def change
    files = Dir[Rails.root + 'app/models/*.rb']
    models = files.map{ |m| File.basename(m, '.rb').camelize }

    if models.include?("ApiClient")
      ApiClient.all.each do |api_client|
        api_key = ApiKey.create!(slug: api_client.slug, label: api_client.label, token: api_client.bearer_token, authentication_strategy: api_client.authentication_strategy)
        ApiNamespaceKey.create(api_namespace_id: api_client.api_namespace_id, api_key_id: api_key.id)
      end
    end
  end
end
