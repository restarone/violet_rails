class CreateExternalApiClients < ActiveRecord::Migration[6.1]
  def change
    create_table :external_api_clients do |t|
      t.references :api_namespace, null: false, foreign_key: true
      t.string :slug, null: false, unique: true
      t.string :label, null: false, default: 'data_source_identifier_here'
      t.jsonb :metadata

      t.timestamps
    end
  end
end
