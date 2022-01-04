class AddRequestHeadersToApiActions < ActiveRecord::Migration[6.1]
  def change
    add_column :api_actions, :custom_headers, :jsonb
    remove_column :api_actions, :custom_message
  end
end
