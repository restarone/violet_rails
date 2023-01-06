class PopulateApiActionParentId < ActiveRecord::Migration[6.1]
  # Since there is no effective way to determine the parent api_action for executed api actions, 
  # this method will only work for api_resource_actions whose parent api_namespace_actions are not updated after execution.

  def up
    ApiNamespace.all.each do |api_namespace|
      api_namespace.api_actions.each do |api_action|
        api_namespace.executed_api_actions.where({
          payload_mapping: api_action.payload_mapping,
          redirect_url: api_action.redirect_url,
          request_url: api_action.request_url,
          email: api_action.email,
          custom_headers: api_action.custom_headers,
          method_definition: api_action.method_definition,
          email_subject: api_action.email_subject,
          type: api_action.type, 
          action_type: api_action.action_type
        }).update_all(parent_id: api_action.id)
      end
    end

    # For executed api actions whose parent_id couldn't be populated, can be updated manually.
    # script to list orphan api actions
    orphan_api_actions = []
    ApiNamespace.all.each do |api_namespace|
      api_namespace.executed_api_actions.where(parent_id: nil).each { |api_action| orphan_api_actions << [api_namespace.id, api_action.id, api_action.api_resource_id]}
    end
    p orphan_api_actions.reject { |c| c.empty? }
  end

  def down
    ApiAction.all.update_all(parent_id: nil)
  end
end
