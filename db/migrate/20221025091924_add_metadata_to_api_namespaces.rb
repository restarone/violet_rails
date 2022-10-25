class AddMetadataToApiNamespaces < ActiveRecord::Migration[6.1]
  def change
    add_column :api_namespaces, :metadata, :jsonb
  end
end
