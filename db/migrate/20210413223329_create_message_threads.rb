class CreateMessageThreads < ActiveRecord::Migration[6.1]
  def change
    create_table :message_threads do |t|
      t.boolean :unread
      t.datetime :deleted_at
      t.string :subject
      t.string :recipients, array: true, default: []
      t.string :current_email_message_id, index: true

      t.timestamps
    end
  end
end