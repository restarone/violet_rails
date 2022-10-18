class CreateWebhookVerificationMethods < ActiveRecord::Migration[6.1]
  def change
    create_table :webhook_verification_methods do |t|
      t.references :external_api_client, null: false, foreign_key: true
      t.string :webhook_type
      t.text :encrypted_webhook_secret
      t.binary :salt

      t.timestamps
    end
  end
end
