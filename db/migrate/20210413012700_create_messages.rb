class CreateMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :messages do |t|
      t.text :title
      t.string :from

      t.timestamps
    end
  end
end
