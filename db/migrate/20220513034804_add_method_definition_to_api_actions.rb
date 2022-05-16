class AddMethodDefinitionToApiActions < ActiveRecord::Migration[6.1]
  def change
    add_column :api_actions, :method_definition, :text, default: "# You have access to variables: api_action, api_namespace, api_resource, current_visit, current_user\n# Write your custom code here\nraise 'not implemented error'"
  end
end
