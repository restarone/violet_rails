class AddIndexToAhoyEventsNameAndTime < ActiveRecord::Migration[6.1]
  def change
    add_index :ahoy_events, :name
    add_index :ahoy_events, :time
  end
end
