class CreateMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :messages do |t|
      t.string :from
      t.references :message_thread, null: false, foreign_key: true
      t.string :email_message_id, index: true

      t.timestamps
    end
  end
end

