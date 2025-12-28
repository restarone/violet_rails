class CreateShortcuts < ActiveRecord::Migration[6.1]
  def change
    create_table :shortcuts do |t|
      t.string :path
      t.string :name
      t.string :slug
      t.references :subdomain, null: false, foreign_key: true

      t.timestamps
    end
  end
end
