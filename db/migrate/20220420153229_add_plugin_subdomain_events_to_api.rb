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
        model_definition: {
          record_id: {
            type: "integer",
            validations: {
              allow_blank: false,
              primary_key: true,
              unique: true
            }
          },
          record_type: {
            type: "string",
            validations: {
              allow_blank: false
            }
          }
        },
        representations: {
          Message: {
            body: {
              type: "string"
            }
          }
        }
      }
    )

    change_table :subdomains do |t|
      t.boolean :api_plugin_events_enabled, default: false
    end
  end
end
