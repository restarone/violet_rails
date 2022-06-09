require "test_helper"

class DynamicAttributeTest < ActiveSupport::TestCase
    setup do
        @api_resource = api_resources(:one)
    end

    models_to_test = {
        ApiAction: [:email_subject, :custom_message, :payload_mapping],
        
    }
    models_to_test.each do |model, columns|
        test  "test #{model}" do
            columns.each do |column|
                obj = model.to_s.constantize.new(api_resource_id: @api_resource.id)
                assert_respond_to obj, "#{column}_evaluated"
            end
        end
    end
end