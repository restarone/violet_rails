class AddRedirectTypeToApiActions < ActiveRecord::Migration[6.1]
  def change
    add_column :api_actions, :redirect_type, :integer, default: 0
  end
end
