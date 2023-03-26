class AddTempPropertiesToApiNamespacesAndBackfill < ActiveRecord::Migration[6.1]
  def up
    add_column :api_namespaces, :temp_properties, :json
    
    ApiNamespace.where(temp_properties: nil).in_batches do |records|
      records.update_all("temp_properties = properties")
    end
  end

  def down
    remove_column :api_namespaces, :temp_properties, if_exists: true
  end
end
