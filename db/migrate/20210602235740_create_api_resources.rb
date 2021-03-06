class CreateApiResources < ActiveRecord::Migration[6.1]
  def change
    create_table :api_resources do |t|
      t.references :api_namespace, null: false, foreign_key: true
      t.jsonb :properties

      t.timestamps
    end
    add_index :api_resources, :properties, using: :gin, opclass: :jsonb_path_ops
  end
end
