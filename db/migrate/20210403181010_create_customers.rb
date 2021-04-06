class CreateCustomers < ActiveRecord::Migration[6.1]
  def change
    create_table :customers do |t|
      t.string :subdomain, unique: true

      t.timestamps
    end
    add_index :customers, :subdomain
  end
end
