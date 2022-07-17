class AddMethodDefinitionToApiActions < ActiveRecord::Migration[6.1]
  def change
    add_column :api_actions, :method_definition, :text
  end
end
