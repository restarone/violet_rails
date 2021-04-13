class CreateMailboxes < ActiveRecord::Migration[6.1]
  def change
    create_table :mailboxes do |t|
      t.boolean :unread
      t.boolean :enabled
      t.integer :threads_count

      t.timestamps
    end
  end
end


