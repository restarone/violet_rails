class AddMethodDefinitionToApiActions < ActiveRecord::Migration[6.1]
  def change
    add_column :api_actions, :method_definition, :text, default: "ApiAction::CustomApiAction.class_eval do\n\tdef run_custom_action(current_user = nil, current_visit, api_object)\n\t\traise 'not implemented error'\n\tend\nend"
  end
end
