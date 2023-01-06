class AddCanAccessForumToUsers < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :can_access_forum, :boolean, default: false

    # Giving all existing users permission to access forum.
    User.update_all(can_access_forum: true)
  end

  def down
    remove_column :users, :can_access_forum
  end
end
