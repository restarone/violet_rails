class AddPluginSubdomainEventsToApi < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.boolean :api_plugin_events_enabled, default: false
    end
  end
end
