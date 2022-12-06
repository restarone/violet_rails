class AddApiAccessibilityToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :api_accessibility, :jsonb, default: {}
  end
end
