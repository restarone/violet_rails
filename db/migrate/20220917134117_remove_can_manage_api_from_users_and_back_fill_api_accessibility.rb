class RemoveCanManageApiFromUsersAndBackFillApiAccessibility < ActiveRecord::Migration[6.1]
  def up
    users_to_be_given_full_access = User.where(can_manage_api: true)
    users_to_be_given_full_access.each do |user|
      user.update(api_accessibility: {all_namespaces: {full_access: 'true'}})
    end

    remove_column :users, :can_manage_api
  end

  def down
    add_column :users, :can_manage_api, :boolean, default: false

    users_to_be_given_api_access =  User.where("api_accessibility#>>'{all_namespaces, full_access}' = ?", "true")
    users_to_be_given_api_access.update_all("can_manage_api": true)
  end
end
