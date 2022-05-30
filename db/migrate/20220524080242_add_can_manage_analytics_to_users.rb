class AddCanManageAnalyticsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :can_manage_analytics, :boolean, default: false
  end
end
