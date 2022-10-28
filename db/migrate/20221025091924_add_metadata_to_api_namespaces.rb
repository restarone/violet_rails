class AddMetadataToApiNamespaces < ActiveRecord::Migration[6.1]
  def change
    add_column :api_namespaces, :social_share_metadata, :jsonb
  end
end
