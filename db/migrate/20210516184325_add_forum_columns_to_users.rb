class AddForumColumnsToUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      t.string :name
      # for forum only
      t.boolean :moderator
    end
  end
end
