class AddPluginSubdomainEventsToApi < ActiveRecord::Migration[6.1]
  def change
    # docs: https://github.com/restarone/violet_rails/issues/430
    ApiNamespace.create!(
      name: 'subdomain/event',
      slug: 'subdomain_events',
      version: 1,
      requires_authentication: true,
      namespace_type: 'create-read-update-delete',
      properties: {
        object: {
          record_id: "required",
          record_type: "required"
        },
        representation: {
          body: ""
        }
      }
    )

    change_table :subdomains do |t|
      t.boolean :api_plugin_events_enabled, default: false
    end
  end
end
