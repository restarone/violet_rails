class CreateSubdomains < ActiveRecord::Migration[6.1]
  def change
    create_table :subdomains do |t|
      t.string :name, unique: true, null: false
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :subdomains, :name
    add_index :subdomains, :deleted_at
  end
end
