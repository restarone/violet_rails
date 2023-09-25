class AddRoomsTable < ActiveRecord::Migration[6.1]
  def change
    create_table :rooms do |t|
      t.string :name
      t.string :external_room_id, null: false
      t.boolean :active, default: true
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
    add_index :rooms, :external_room_id, unique: true
  end
end
