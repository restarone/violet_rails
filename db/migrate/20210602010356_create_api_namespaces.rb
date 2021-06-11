class CreateApiNamespaces < ActiveRecord::Migration[6.1]
  def change
    create_table :api_namespaces do |t|
      t.string :name, null: false
      t.string :slug, null: false, unique: true
      t.integer :version, null: false
      t.jsonb :properties
      t.boolean :requires_authentication, default: false
      t.string :namespace_type, default: 'create-read-update-delete', null: false

      t.timestamps
    end
  end
end
