class CreateApiClients < ActiveRecord::Migration[6.1]
  def change
    create_table :api_clients do |t|
      t.references :api_namespace, null: false, foreign_key: true
      t.string :slug, null: false, unique: true
      t.string :label, null: false, default: 'customer_identifier_here'
      t.string :authentication_strategy, null: false, default: 'bearer_token'
      t.string :bearer_token, unique: true

      t.timestamps
    end
    add_index :api_clients, :bearer_token
  end
end
