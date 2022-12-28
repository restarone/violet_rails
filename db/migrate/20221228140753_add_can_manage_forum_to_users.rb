class AddCanManageForumToUsers < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :can_manage_forum, :boolean, default: false

    # Giving all existing users permission to manage forum.
    User.update_all(can_manage_forum: true)
  end

  def down
    remove_column :users, :can_manage_forum
  end
end
