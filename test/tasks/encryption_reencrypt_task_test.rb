require "test_helper"
require "rake"

class EncryptionReencryptTaskTest < ActiveSupport::TestCase
  setup do
    @api_namespace = api_namespaces(:one)
    Sidekiq::Testing.fake!
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    ApiAction.destroy_all
  end

  test 'should be able to access encrypted secret after changeing SECRET_KEY_BASE' do
    Rails.application.secrets.secret_key_base = 'test_123'

    api_action = CreateApiAction.create(api_namespace_id: @api_namespace.id, action_type: 'send_web_request', bearer_token: 'my_bearer_token')
    api_key = ApiKey.create(label: 'test', authentication_strategy: 'bearer_token')

    api_key_token = api_key.token

    assert_equal 'my_bearer_token', api_action.bearer_token
    Rails.application.secrets.secret_key_base = 'new_test_123'
    ENV['OLD_SECRET_KEY_BASE'] = 'test_123'
  
    Object.send(:remove_const, :EncryptionService)
    load 'app/services/encryption_service.rb'

    assert_raises(ActiveSupport::MessageEncryptor::InvalidMessage) do
      api_action.reload.bearer_token
      api_key.reload.token
    end

    Rake::Task["encryption:reencrypt"].invoke

    assert_equal 'my_bearer_token', api_action.reload.bearer_token
    assert_equal api_key_token, api_key.reload.token
  end
end