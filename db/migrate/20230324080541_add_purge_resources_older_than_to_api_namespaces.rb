class AddPurgeResourcesOlderThanToApiNamespaces < ActiveRecord::Migration[6.1]
  def change
    add_column :api_namespaces, :purge_resources_older_than, :string, default: 'never'
  end
end
