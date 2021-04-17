class CreateMailboxes < ActiveRecord::Migration[6.1]
  def change
    create_table :mailboxes do |t|
      t.boolean :unread, default: false
      t.boolean :enabled, default: false
      t.integer :threads_count, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end


