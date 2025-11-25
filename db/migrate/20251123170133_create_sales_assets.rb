class CreateSalesAssets < ActiveRecord::Migration[6.1]
  def change
    create_table :sales_assets do |t|
      t.string :name
      t.string :slug
      t.integer :width
      t.integer :height
      t.text :html

      t.timestamps
    end
  end
end
