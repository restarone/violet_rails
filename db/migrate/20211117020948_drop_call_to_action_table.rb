class DropCallToActionTable < ActiveRecord::Migration[6.1]
  def up
    drop_table :call_to_action_responses
    drop_table :call_to_actions
  end
  
  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
