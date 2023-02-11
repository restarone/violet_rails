class AddAnalyticsMetadataToApiNamespace < ActiveRecord::Migration[6.1]
  def change
    add_column :api_namespaces, :analytics_metadata, :jsonb
  end
end
