require "test_helper"

class ApiActionMailerTest < ActionMailer::TestCase
    test 'sends email wihout api resource if not included in api action' do
        @api_action_1 = api_actions(:error_api_action_one)
        @api_action_1.update(email_subject: "")
        @api_action_2 = ErrorApiAction.create(@api_action_1.attributes.merge(custom_message: @api_action_1.custom_message.to_s, parent_id: @api_action_1.id, meta_data: { api_resource: {} }).except("id", "created_at", "updated_at", "api_namespace_id"))

        email = ApiActionMailer.send_email(@api_action_2)
        assert_emails 1 do
            email.deliver_later
        end
        assert_equal "#{@api_action_2.type} #{@api_action_2.api_namespace_action&.api_namespace&.name.pluralize} v#{@api_action_2.api_namespace_action&.api_namespace&.version}",email.subject
    end

    test 'sends email with api resource if included in api action' do
        @api_action_1 = api_actions(:error_api_action_one_with_api_resource_data)
        @api_action_1.update(email_subject: "")
        @api_action_2 = ErrorApiAction.create(@api_action_1.attributes.merge(custom_message: @api_action_1.custom_message.to_s, parent_id: @api_action_1.id, meta_data: { api_resource: {} }).except("id", "created_at", "updated_at", "api_namespace_id"))

        email = ApiActionMailer.send_email(@api_action_2)
        assert_emails 1 do
            email.deliver_later
        end
        assert_equal "#{@api_action_2.type} #{@api_action_2.api_namespace_action&.api_namespace&.name.pluralize} v#{@api_action_2.api_namespace_action&.api_namespace&.version}",email.subject
    end
end