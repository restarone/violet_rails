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

  test 'should support erb syntax' do
    api_resource_test = api_resources(:user)
    erb_syntax = '<% food = "Ice cream" %>'\
                 '<div>I like <%= food %></div>'\
                 '<% if api_resource.properties["boolean"] %>'\
                  '<div><%= api_resource.properties["first_name"] %></div>'\
                 '<% end %>' 
    
    safe_instance = @dummy_class.new(test_column: erb_syntax)
    safe_instance.api_resource = api_resource_test
    assert safe_instance.valid?
    assert_respond_to safe_instance, :test_column_evaluated
    assert_equal safe_instance.test_column_evaluated, "<div>I like Ice cream</div>"

    api_resource_test.update(properties: api_resource_test.properties.merge({"boolean": true}))
    assert_equal safe_instance.test_column_evaluated, "<div>I like Ice cream</div><div>#{api_resource_test.properties['first_name']}</div>"
  end

  test 'should raise invalid record error if erb contains unsafe string' do
    unsafe_instance = @dummy_class.new(test_column: "Test <% User.destroy_all %>")
    refute unsafe_instance.valid?
    assert_no_difference "User.all.size" do
      assert_raises ActiveRecord::RecordInvalid do
        unsafe_instance.test_column_evaluated
      end
    end
  end

  test 'should be able to access current_user and current_visit' do
    erb_syntax = "<%= current_user.id %> and <%= current_visit.id %>"

    Current.user = users(:one)
    Current.visit = ahoy_visits(:public)

    safe_instance = @dummy_class.new(test_column: erb_syntax)
    assert_equal safe_instance.test_column_evaluated, "#{Current.user.id} and #{Current.visit.id}"
  end

  test 'should raise standard error if undefined methods are referenced' do
    safe_instance = @dummy_class.new(test_column: "<%= undefined_method() %>")
    assert_raises NoMethodError do
      safe_instance.test_column_evaluated
    end
  end

  test 'should raise syntax error if erb syntax is wrong' do
    # notice the missing closing end for if
    erb_syntax = '<% if true %>'\
                    '<div>Violet Rails</div>'

    safe_instance = @dummy_class.new(test_column: erb_syntax)
    assert_raises SyntaxError do
      safe_instance.test_column_evaluated
    end
  end
end