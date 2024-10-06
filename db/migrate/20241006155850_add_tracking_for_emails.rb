class AddTrackingForEmails < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :opened, :boolean, default: false
    add_column :subdomains, :track_email_opens, :boolean, default: false
  end
end
