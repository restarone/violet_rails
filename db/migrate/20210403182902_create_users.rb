class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.boolean :global_admin, default: false
      t.timestamps
    end
  end
end
