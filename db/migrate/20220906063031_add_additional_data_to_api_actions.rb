class AddAdditionalDataToApiActions < ActiveRecord::Migration[6.1]
  def change
    add_column :api_actions, :meta_data, :jsonb, default: {}
  end
end
