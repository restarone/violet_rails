class CreateExternalApiClients < ActiveRecord::Migration[6.1]
  def change
    create_table :external_api_clients do |t|
      t.references :api_namespace, null: false, foreign_key: true
      t.string :slug, null: false, unique: true
      t.string :label, null: false, default: 'data_source_identifier_here'
      t.string :status, null: false, default: ExternalApiClient::STATUSES[:stopped].to_s
      t.boolean :enabled, default: false
      t.string :error_message
      t.string :drive_strategy, null: false, default: ExternalApiClient::DRIVE_STRATEGIES[:on_demand].to_s
      t.integer :max_requests_per_minute, null: false, default: 0
      t.integer :current_requests_per_minute, null: false, default: 0
      t.integer :max_workers, null: false, default: 0
      t.integer :current_workers, null: false, default: 0
      t.integer :retry_in_seconds, null: false, default: 0
      t.integer :max_retries, null: false, default: 1
      t.integer :retries, null: false, default: 0
      
      t.jsonb :state_metadata
      t.jsonb :error_metadata
      t.jsonb :metadata

      t.timestamps
    end
  end
end
