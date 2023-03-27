# frozen_string_literal: true

class AddPluginSubdomainEventsToApi < ActiveRecord::Migration[6.1]
  def up
    # docs: https://github.com/restarone/violet_rails/issues/430

    return if ApiNamespace.friendly.find_by(slug: 'subdomain_events').present?

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
        }
      }
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
