class AddTrackingToggleToSubdomains < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.boolean :tracking_enabled, default: false
    end
  end
end
