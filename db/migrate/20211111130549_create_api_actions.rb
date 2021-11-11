class CreateApiActions < ActiveRecord::Migration[6.1]
  def change
    create_table :api_actions do |t|
      t.integer :trigger, default: 0
      t.integer :action_type, default: 0
      t.boolean :include_api_resource_data
      t.text :custom_message
      t.jsonb :payload_mapping
      t.string :redirect_url
      t.integer :position
      t.string :email
      t.references :api_namespace, null: false, foreign_key: true

      t.timestamps
    end
  end
end
