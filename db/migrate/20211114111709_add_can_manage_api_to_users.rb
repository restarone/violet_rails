class AddCanManageApiToUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      t.boolean :can_manage_api, default: false
    end
  end
end
