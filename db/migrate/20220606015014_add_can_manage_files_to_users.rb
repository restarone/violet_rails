class AddCanManageFilesToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :can_manage_files, :boolean, default: false
  end
end
