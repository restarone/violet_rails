class AddAssociationsToApiNamespace < ActiveRecord::Migration[6.1]
  def change
    add_column :api_namespaces, :associations, :jsonb, default: []
  end
end
