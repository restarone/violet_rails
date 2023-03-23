class ChangePropertiesInApiNamespacesFromJsonbToJson < ActiveRecord::Migration[6.1]
  def up
    remove_index :api_namespaces, name: "index_api_namespaces_on_properties"

    change_column :api_namespaces, :properties, :json
  end

  def down
    change_column :api_namespaces, :properties, :jsonb

    add_index :api_namespaces, :properties, using: :gin, opclass: :jsonb_path_ops
  end
end
