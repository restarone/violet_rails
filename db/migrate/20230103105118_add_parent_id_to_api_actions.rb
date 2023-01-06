class AddParentIdToApiActions < ActiveRecord::Migration[6.1]
  def change
    add_column :api_actions, :parent_id, :integer
  end
end
