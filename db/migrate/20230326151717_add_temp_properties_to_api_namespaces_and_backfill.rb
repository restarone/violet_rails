class AddTempPropertiesToApiNamespacesAndBackfill < ActiveRecord::Migration[6.1]
  def up
    safety_assured { add_column :api_namespaces, :temp_properties, :json }
    
    ApiNamespace.where(temp_properties: nil).update_all("temp_properties = properties")
  end

  def down
    remove_column :api_namespaces, :temp_properties, if_exists: true
  end
end
