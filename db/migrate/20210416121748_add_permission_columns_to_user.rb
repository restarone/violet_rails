class AddPermissionColumnsToUser < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      t.boolean :can_manage_web, default: false
      t.boolean :can_manage_email, default: false
      t.boolean :can_manage_users, default: false
    end
  end
end
