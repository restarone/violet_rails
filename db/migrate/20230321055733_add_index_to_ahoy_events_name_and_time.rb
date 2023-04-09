class AddIndexToAhoyEventsNameAndTime < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :ahoy_events, :name, algorithm: :concurrently
    add_index :ahoy_events, :time, algorithm: :concurrently
  end
end
