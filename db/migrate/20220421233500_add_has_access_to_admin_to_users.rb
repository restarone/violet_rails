class AddHasAccessToAdminToUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      # moving forward all users will need to be opted-in to being able to access admin
      t.boolean :can_access_admin, default: false
    end
    # before this commit (April 21 2022) all users of Violet Rails had admin permissions. To avoid confusion we are setting this flag to true in the migration
    
    User.update_all(can_access_admin: true)
  end
end
