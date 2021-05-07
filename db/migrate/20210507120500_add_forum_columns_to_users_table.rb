class AddForumColumnsToUsersTable < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      t.string :name
      # for forum only
      t.boolean :moderator
      t.boolean :admin
    end
  end
end
