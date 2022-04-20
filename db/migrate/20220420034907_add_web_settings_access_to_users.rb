class AddWebSettingsAccessToUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      t.boolean :can_manage_subdomain_settings, default: false
    end
  end
end
