class CreateApiNamespaceKeys < ActiveRecord::Migration[6.1]
  def change
    create_table :api_namespace_keys do |t|
      t.belongs_to :api_namespace, null: false, foreign_key: true
      t.belongs_to :api_key, null: false, foreign_key: true

      t.timestamps
    end
  end
end
