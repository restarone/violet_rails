class CreateMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :messages do |t|
      t.text :title
      t.string :from
      t.references :message_thread,   null: false, polymorphic: true, index: false

      t.timestamps
    end
  end
end

