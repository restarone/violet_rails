require "test_helper"

class DynamicAttributeTest < ActiveSupport::TestCase
  setup do
    # test concern in isolation
    @dummy_class = Class.new do
      include ActiveModel::Model

      def self.name
        'Test'
      end

      def initialize(test_column: nil)
          @test_column = test_column
      end

      include ActiveModel::Validations
      include DynamicAttribute
      attr_accessor :test_column
      attr_accessor :api_resource

      attr_dynamic :test_column
    end
  end  

  test 'should respond to dynamic methods if dynamic field is safe' do
    safe_instance = @dummy_class.new(test_column: "Test \#{1 + 1}")
    assert safe_instance.valid?
    assert_respond_to safe_instance, :test_column_evaluated
    assert_equal safe_instance.test_column_evaluated, 'Test 2'
  end


  test 'should raise invalid record error dynamic field contains unsafe string' do
    unsafe_instance = @dummy_class.new(test_column: "Test \#{User.destroy_all}")
    refute unsafe_instance.valid?
    assert_no_difference "User.all.size" do
      assert_raises ActiveRecord::RecordInvalid do
        unsafe_instance.test_column_evaluated
      end
    end
  end
end