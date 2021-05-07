class AddForumColumnsToUsersTable < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      # for forum only
      t.string :name
      t.boolean :moderator
      t.boolean :admin
    end
  end
end
