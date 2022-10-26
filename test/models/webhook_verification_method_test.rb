require "test_helper"

class WebhookVerificationMethodTest < ActiveSupport::TestCase
  setup do
    @external_api_client = external_api_clients(:webhook_drive_strategy)
  end

  test 'should be invalid if users private attributes are accessed' do
    User::PRIVATE_ATTRIBUTES.each do |private_attr|
      webhook_verification_method = WebhookVerificationMethod.new(webhook_type: 'custom', external_api_client_id: @external_api_client.id, webhook_secret: 'secret', custom_method_defination: "User.last.#{private_attr}")
      refute webhook_verification_method.valid?
      assert_includes webhook_verification_method.errors.messages[:custom_method_defination].to_s, 'contains disallowed keyword'
    end
  end

  test 'should be invalid if users permissions are referenced' do
    User::FULL_PERMISSIONS.keys.each do |permission_attr|
      webhook_verification_method = WebhookVerificationMethod.new(webhook_type: 'custom', external_api_client_id: @external_api_client.id, webhook_secret: 'secret', custom_method_defination: "User.last.update(#{permission_attr} => false)")
      refute webhook_verification_method.valid?
      assert_includes webhook_verification_method.errors.messages[:custom_method_defination].to_s, 'contains disallowed keyword'
    end
  end

  test 'should be invalid if blacklisted keywords are present' do
    invalid_model_definations = [
      'Subdomain.destroy_all',
      'exit()',
      'subdomain.constantize.last.update(id: 1)',
      'eval("1 + 1")',
      'User.last.update(can_manage_users: true)',
      'User.send(:new)',
      '#{User.destroy_all}'
    ]

    invalid_model_definations.each do |invalid_executable|
      webhook_verification_method = WebhookVerificationMethod.new(webhook_type: 'custom', external_api_client_id: @external_api_client.id, webhook_secret: 'secret', custom_method_defination: invalid_executable)
      refute webhook_verification_method.valid?
      assert_includes webhook_verification_method.errors.messages[:custom_method_defination].to_s, 'contains disallowed keyword'
    end
  end
end
