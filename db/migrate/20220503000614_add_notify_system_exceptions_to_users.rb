class AddNotifySystemExceptionsToUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      t.boolean :deliver_error_notifications, default: false
    end
  end
end
