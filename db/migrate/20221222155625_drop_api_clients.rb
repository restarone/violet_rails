class DropApiClients < ActiveRecord::Migration[6.1]
  def up
    drop_table :api_clients
  end
  
  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
