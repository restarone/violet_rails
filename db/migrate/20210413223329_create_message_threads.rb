class CreateMessageThreads < ActiveRecord::Migration[6.1]
  def change
    create_table :message_threads do |t|
      t.boolean :unread
      t.datetime :deleted_at
      t.string :subject
      t.string :recipients, array: true, default: []
      t.references :mailbox, null: false, foreign_key: true
      t.string :email_message_id, null: false, index: true

      t.timestamps
    end
  end
end