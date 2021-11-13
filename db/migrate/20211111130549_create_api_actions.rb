class CreateApiActions < ActiveRecord::Migration[6.1]
  def change
    create_table :api_actions do |t|
      t.integer :trigger, default: 0
      t.integer :action_type, default: 0
      t.boolean :include_api_resource_data
      t.text :custom_message
      t.jsonb :payload_mapping
      t.string :redirect_url
      t.string :request_url
      t.integer :position
      t.string :email
      t.string :file_snippet
      t.string :bearer_token
      t.string :lifecycle_message
      t.integer :lifecycle_stage, default: 0
      t.references :api_namespace, foreign_key: true
      t.references :api_resource, foreign_key: true

      t.timestamps
    end
  end
end
