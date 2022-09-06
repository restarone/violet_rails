class AddAdditionalDataToApiActions < ActiveRecord::Migration[6.1]
  def change
    add_column :api_actions, :additional_data, :jsonb, default: {}
  end
end
