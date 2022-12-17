class AddEmailNotificationStrategyToSubdomain < ActiveRecord::Migration[6.1]
  def change
    add_column :subdomains, :email_notification_strategy, :string, default: 'user_email'
  end
end
